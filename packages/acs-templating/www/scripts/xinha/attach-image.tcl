ad_page_contract {
    Simple image upload, attach image to object_id passed in, if no
    object_id, use the current package_id
    @author Guenter Ernst guenter.ernst@wu-wien.ac.at, 
    @author Gustaf Neumann neumann@wu-wien.ac.at
    @author Dave Bauer (dave@solutiongrove.com)
    @creation-date 13.07.2004
    @cvs-id $Id$
} {
    {parent_id:integer,optional}
    {package_id ""}
    {selector_type "image"}
}

set f_url ""

set user_id [auth::require_login]

# if user has write permission, create image upload form, 

if {![info exists parent_id]} {
    set parent_id $user_id
    set write_p 1
} else {

    set write_p [permission::permission_p \
		     -party_id $user_id \
		     -object_id $parent_id \
		     -privilege "write"]
}

if {!$write_p} {
    # if parent_id does not exist yet, let's use the pacakage_id
    if { ![db_0or1row "check_parent" "select object_id from acs_objects where object_id=:parent_id"] } {
        set parent_id $package_id
    }

    # item might not exist!
    set write_p [permission::permission_p \
		     -party_id $user_id \
		     -object_id $package_id \
		     -privilege "write"]
}

set recent_images_options [list]

if {$write_p} {
    # set recent images
    # db_multirow -unclobber recent_images recent_images \
	# {
	    # select ci.item_id, ci.name
	    # from cr_items ci, cr_revisionsx cr, cr_child_rels ccr
	    # where ci.live_revision=cr.revision_id
	    # and ci.content_type='image'
	    # and cr.creation_user=:user_id
	    # and ccr.parent_id=ci.item_id
	    # and ccr.relation_tag='image-thumbnail'
	    # order by creation_date desc
	    # limit 6
	# } {
	    # set name [regsub "${item_id}_" $name ""] 	    
	    # lappend recent_images_options [list $name $item_id]
	# }
    


    set share_options [list [list "[_ acs-templating.Only_myself]" private] [list "[_ acs-templating.This_Group]" group] [list "[_ acs-templating.Anyone_on_this_system]" site] [list "[_ acs-templating.Anyone_on_the_internet]" public]]

    ad_form \
        -name upload_form \
        -mode edit \
        -export {selector_type file_types parent_id} \
        -html { enctype multipart/form-data  } \
        -form {
            item_id:key
            {package_id:text(hidden),optional}
	    	{choose_file:text(radio),optional {options $recent_images_options}}
            {upload_file:file(file),optional {html {size 30}} }
            {share:text(radio),optional {label "[_ acs-templating.This_image_can_be_reused_by]"} {options $share_options} {help_text "[_ acs-templating.This_image_can_be_reused_help]"}}
	    	{select_btn:text(submit) {label "[_ acs-templating.Add_the_selected_image]"}}
            {upload_btn:text(submit) {label "[_ acs-templating.HTMLArea_SelectUploadBtn]"}
            }
        } \
        -on_request {
            set share site
            set package_id $package_id
        } \
        -on_submit {
            # check file name
	    
            if {$choose_file eq "" && $upload_file eq ""} {
                template::form::set_error upload_form upload_file \
                    [_ acs-templating.HTMLArea_SpecifyUploadFilename]
                break
            }
	    if {$upload_file ne "" } {

              if {[info exists folder_size]} {
                  # check per folder quota 
                  set maximum_folder_size [parameter::get -parameter "MaximumFolderSize"]
        
                  if { $maximum_folder_size ne "" } {
                    if { $folder_size+[file size ${upload_file.tmpfile}] > $maximum_folder_size } {
                      template::form::set_error upload_form upload_file \
                          [_ file-storage.out_of_space]
                      break
                    }
                  }
                }
		
		set file_name [template::util::file::get_property filename $upload_file]
		set upload_tmpfile [template::util::file::get_property tmp_filename $upload_file]
		set mime_type [template::util::file::get_property mime_type $upload_file]
		if {$mime_type eq ""} {
		    set mime_type [ns_guesstype $file_name] 
		}
		if {![string match "image/*" $mime_type]} {
		    template::form::set_error upload_form upload_file \
			[_ acs-templating.HTMLArea_SelectImageUploadNoImage]
		    break                
		}

		image::new \
		    -item_id $item_id \
		    -name ${item_id}_$file_name \
		    -parent_id $parent_id \
		    -tmp_filename $upload_tmpfile \
		    -creation_user $user_id \
		    -creation_ip [ad_conn peeraddr] \
		    -package_id [ad_conn package_id] \
		    -mime_type $mime_type
		
		# create thumbnail
		image::resize -item_id $item_id
		
		file delete $upload_tmpfile
		
		permission::grant \
		    -object_id $item_id \
		    -party_id $user_id \
		    -privilege admin

		switch -- $share {
		    private {
			permission::set_not_inherit -object_id $item_id
			set f_url "/image/${item_id}/private/${parent_id}/${file_name}"		
		    }
		    group {
			# Find the closest application group
			# either dotlrn or acs-subsite
			
			permission::grant \
			    -party_id [acs_magic_object "registered_users"] \
			    -object_id $item_id \
			    -privilege "read"
		    }
		    public {
			permission::grant \
			    -party_id [acs_magic_object "the_public"] \
			    -object_id $item_id \
			    -privilege "read"
		    }
		    site -
		    default {
			permission::grant \
			    -party_id [acs_magic_object "registered_users"] \
			    -object_id $item_id \
			    -privilege "read"
		    }
		    
		}
	    } else {
		# user chose an existing file
		set item_id $choose_file 
		set file_name [lindex [lindex $recent_images_options [util_search_list_of_lists $recent_images_options $item_id 1]] 0]
	    }
		set f_url "/image/${item_id}/${file_name}"			    
	}
    
} else {
    set write_p 0
}
# default to xinha but tinymce will work too. no plugins for rte
set richtextEditor [parameter::get \
			-package_id [ad_conn package_id] \
			-parameter "RichTextEditor" \
			-default "xinha"]

set HTML_Preview "Preview"
set HTML_UploadTitle ""

################################################################################

set ajaxhelper_p [apm_package_installed_p ajaxhelper]
if {$ajaxhelper_p} {
    ah::requires -sources "prototype,scriptaculous"
}

if {$richtextEditor eq "xinha"} {
template::head::add_javascript \
    -order "Z0" \
    -src "/resources/acs-templating/xinha-nightly/popups/popup.js"
template::head::add_javascript \
    -order "Z1" \
    -script "
	var selector_window;
	// window.resizeTo(415, 300);
	
	function Init() {
	  __dlg_init();
	  var param = window.dialogArguments;
	  if (param) {
	      document.getElementById('f_url').value = param\['f_url'\];
	      document.getElementById('f_alt').value = param\['f_alt'\];
	      document.getElementById('f_border').value = param\['f_border'\];
	      document.getElementById('f_align').value = param\['f_align'\];
	      document.getElementById('f_vert').value = param\['f_vert'\];
	      document.getElementById('f_horiz').value = param\['f_horiz'\];

	      window.ipreview.location.replace(param.f_url);
	  }
	  // document.getElementById('f_url').focus();
	  var f_url = document.getElementById('f_url');
	  var url = f_url.value;
	  if (url) {
      		 onOK();
	      	 __dlg_close(null);
	  }
	};
	
	function onOK() {
	  var required = {
	    'f_url': '#acs-templating.HTMLArea_NoURL#'
	  };
	  for (var i in required) {
	    var el = document.getElementById(i);
	    if (!el.value) {
	      alert(required\[i\]);
	      el.focus();
	      return false;
	    }
	  }
	  // pass data back to the calling window
	  var param = new Object();
	  /* 
	  var fields = \['f_url'\];
	  for (var i in fields) {
	    var id = fields\[i\];
	    var el = document.getElementById(id);
	    param\[id\] = el.value;
	  } 
	  */
	  param\['f_url'\] = document.getElementById('f_url').value;
	  if (selector_window) {
	    selector_window.close();
	  }
	  __dlg_close(param);
	  return false;
	};
	
	function onCancel() {
	  if (selector_window) {
	    selector_window.close();
	  }
	  __dlg_close(null);
	  return false;
	};

	function onPreview() {
	  var f_url = document.getElementById('f_url');
	  var url = f_url.value;
	  if (!url) {
	    alert('You have to enter an URL first');
	    f_url.focus();
	    return false;
	  }
	  if (document.getElementById('preview_div').style.display == 'none') { 
		document.getElementById('showpreview').click();
	  }
	  window.ipreview.location.replace(url);
	  return false;
	};

	function resizeWindow(formname) {
		var w, h;
		if (formname == 'url') {
			w = 415;
			h = 330;
		}
		if (formname == 'upload') {
			w = 415;
			h = 310;
		}
		if (document.getElementById('showpreview').checked == true) {
			h = h + 200;
		}
		window.resizeTo(w, h);
	}

	function togglePreview() {
		var w = window.clientWidth;
		var h = window.clientHeight;
		if (document.getElementById('preview_div').style.display == 'none') { 
			document.getElementById('preview_div').style.display='';
		} else { 
			document.getElementById('preview_div').style.display='none'; 
		}
		if (document.getElementById('insert_image_url').style.display == 'none') { 
			resizeWindow('upload');
		} else { 
			resizeWindow('url');
		}		
	}
	
        </script>"

}

if {$richtextEditor eq "tinymce"} {
    template::head::add_javascript \
        -order "Z1" \
        -src "/resources/acs-templating/tinymce/jscripts/tiny_mce/tiny_mce_popup.js"
    template::head::add_javascript \
        -order "Z2" \
        -src "/resources/acs-templating/tinymce/jscripts/tiny_mce/plugins/oacsimage/js/image.js"

template::head::add_style \
    -style "
	html, body {
	  background: ButtonFace;
	  color: ButtonText;
	  font: 11px Tahoma,Verdana,sans-serif;
	  margin: 0px;
	  padding: 0px;
	}
	body { padding: 5px; }
	table {
	  font: 11px Tahoma,Verdana,sans-serif;
	}
	form p {
	  margin-top: 5px;
	  margin-bottom: 5px;
	}
	.fl { width: 9em; float: left; padding: 2px 5px; text-align: right; }
	.fr { width: 6em; float: left; padding: 2px 5px; text-align: right; }
	fieldset { padding: 0px 10px 5px 5px; }
	select, input, button { font: 11px Tahoma,Verdana,sans-serif; }
	.space { padding: 2px; }
	
	.title { background: #ddf; color: #000; font-weight: bold; font-size: 120%; padding: 3px 10px; margin-bottom: 10px;
	border-bottom: 1px solid black; letter-spacing: 2px;
	}
	form { padding: 0px; margin: 0px; }
	.form-error { color : red}
	#html-carousel {
		background: #f5f4e4; 
	} 
	#html-carousel .carousel-list li {
		margin:4px 0px 0px 0px; 
	} 
	#html-carousel .carousel-list li {
		width: 106px;
		border: 0px solid green;
		padding: 2px;
		padding-top: 15px;
		margin: 0;
		color: #3F3F3F; 
	} 
	#html-carousel .carousel-list li img {
		border:1px solid #999;
		display:block; 
		width:100px;
	} 
	#html-carousel {
		margin-bottom: 10px;
		float: left;     
		width: 330px;;     
		height: 155px; 
	} 
	/* BUTTONS */ 
	#prev-arrow-container, #next-arrow-container {
		float:left;
		margin: 1px;
		padding: 0px; 
	} 
	#next-arrow {
		cursor:pointer; 
		float:right;
	} 
	#prev-arrow {
		cursor:pointer; 
	} 
	
	/* Overlay */
	#overlay {
	  width: 200px;
	  height: 80px;
	  background-color:  #FFF;
	  position: absolute;
	  top: 25px;
	  left: 80px;
	  padding-top: 10px;
	  z-index: 100;
	  color: #000;
	  border:1px dotted #000;	
		text-align: center;
		font-size: 24px;
	  filter:alpha(opacity=80);
		-moz-opacity: 0.8;
		opacity: 0.8;
	}
"
    if {$ajaxhelper_p} {
        template::head::add_css \
            -href "/resources/ajaxhelper/carousel/carousel.css"
        template::head::add_javascript \
            -order "Z4" \
            -src "/resources/ajaxhelper/carousel/carousel.js"
        
        template::head::add_javascript \
            -order "Z5" \
            -script "

var carousel;
								
var buttonStateHandler = function (button, enabled) {
	if (button == 'prev-arrow') {
		\$('prev-arrow').src = enabled ? '/resources/ajaxhelper/carousel/left-enabled.gif' : '/resources/ajaxhelper/carousel/left-disabled.gif'
	} else {
		\$('next-arrow').src = enabled ? '/resources/ajaxhelper/carousel/right-enabled.gif' : '/resources/ajaxhelper/carousel/right-disabled.gif'
	}
}

var ajaxHandler = function (carousel, status) {  
	var overlay = \$('overlay');   
	if (status == 'before') {     
		if (overlay) {       
			overlay.setOpacity(0);       
			overlay.show();       
			Effect.Fade(overlay, {from: 0, to: 0.8, duration: 0.2})     
		} else {
		  new Insertion.Top('html-carousel', \"<div id='overlay' ><br>Loading...<br><img src='/resources/ajaxhelper/images/indicator.gif'></div>\");   
		}
	} else {
		Effect.Fade(overlay, {from: 0.8, to: 0.0, duration: 0.2}) 
	}
} 			

function initCarousel_html_carousel() {
    carousel = new Carousel('html-carousel', {ajaxHandler:ajaxHandler, animParameters:{duration:0.5}, buttonStateHandler:buttonStateHandler, nextElementID:'next-arrow', prevElementID:'prev-arrow', url:'/ajax/xmlhttp/carousel-images'})
}
"
}
    template::head::add_javascript \
        -order "Z3" \
        -script "
function attachImageInit() {
    var param = window.dialogArguments;

    var f_url = document.getElementById('f_url');
    var url = f_url.value;

    if (url) {
         ImageDialog.insertAndClose();
    } else {
        if (${ajaxhelper_p}) {
            initCarousel_html_carousel();
        }
        tinyMCEPopup.executeOnLoad('init();');
	}
}
function onCancel() { 
	tinyMCEPopup.close();  
}

"
template::add_body_handler \
    -event onload \
    -script "attachImageInit()"

}

