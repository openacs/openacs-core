ad_page_contract {
    Simple file upload, attach image to object_id passed in, if no
    object_id, use the current package_id
    @author Guenter Ernst guenter.ernst@wu-wien.ac.at, 
    @author Gustaf Neumann neumann@wu-wien.ac.at
    @author Dave Bauer (dave@solutiongrove.com)
    @creation-date 13.07.2004
    @cvs-id $Id$
} {
    {parent_id:integer,optional}
    {package_id ""}
    {selector_type "file"}
    {f_href ""}
}

#HAM : ajax sources
#ah::requires -sources "prototype,scriptaculous"

set f_url ""

set user_id [auth::require_login]

# if user has write permission, create image upload form, 

if {![info exists parent_id] || $parent_id eq ""} {
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

if {$write_p} {
    # set recent files
    set recent_files_options [list]
    db_multirow -extend {mime_icon} -unclobber recent_files recent_files \
	{
	    select ci.item_id, ci.name, cr.mime_type
	    from cr_items ci, cr_revisionsx cr
	    where ci.live_revision=cr.revision_id
	    and ci.content_type='content_revision'
            and storage_type='file'
	    and cr.creation_user=:user_id
            and cr.mime_type is not null
	    order by creation_date desc
	    limit 6
	} {
	    set mime_icon "/resources/acs-templating/mimetypes/gnome-mime-[string map {/ -} $mime_type].png"
	    set name [regsub "${item_id}_" $name ""]
	    set name "<img src=\"$mime_icon\"/> $name"
	    lappend recent_files_options [list $name $item_id]
	}
#    ns_log notice "HAM : recent_files_options : $recent_files_options ********************"
    
    set share_options [list [list "[_ acs-templating.Only_myself]" private] [list "[_ acs-templating.This_Group]" group] [list "[_ acs-templating.Anyone_on_this_system]" site] [list "[_ acs-templating.Anyone_on_the_internet]" public]]
    ad_form \
        -name upload_form \
        -mode edit \
        -export {selector_type file_types parent_id} \
        -html { enctype multipart/form-data } \
        -form {
	    item_id:key
	    {package_id:text(hidden),optional}
	    {f_href:text(hidden),optional {html {id f_href}}}
	    {f_title:text,optional {label "[_ acs-templating.Link_Title]"} {html {size 50 id f_title} } }
	    {f_url:url,optional {label "[_ acs-templating.Link_Url]"} {html {size 50 id f_url } } }
	    {url_ok_btn:text(submit) {label "[_ acs-templating.Link_Url_Btn]"} }
	    {choose_file:text(radio),optional {options $recent_files_options}}
            {upload_file:file(file),optional {html {size 30}} }
            {share:text(radio),optional {label "[_ acs-templating.This_file_can_be_reused_by]"} {options $share_options} {help_text "[_ acs-templating.This_file_can_be_reused_help]"}}
	    {select_btn:text(submit) {label "[_ acs-templating.Add_the_selected_file]"}}
            {ok_btn:text(submit) {label "[_ acs-templating.HTMLArea_SelectUploadBtn]"}
            }
        } \
        -on_request {
            set share site
	    if {$f_href ne ""} {
		set f_url $f_href
	    }
        } \
        -on_submit {
	    if {$f_href eq ""} {
		set f_href $f_url
		element set_value upload_form f_href $f_href
	    }
	    # ensure that Link Title is specified
	    if { ![exists_and_not_null f_title] && [exists_and_not_null url_ok_btn] } {
		template::form::set_error upload_form f_title "Specify a [_ acs-templating.Link_Title]"
	    }
	    set error_p 0
            # check file name
		if { [info exists f_url] && $f_url eq "" && $url_ok_btn ne ""} {
		    template::form::set_error upload_form f_url "Specify a [_ acs-templating.Link_Url]"
		    set error_p 1
		} 
		if {[info exists ok_btn] && $ok_btn ne "" && $upload_file eq ""} {
		    template::form::set_error upload_form upload_file \
			[_ acs-templating.HTMLArea_SpecifyUploadFilename]
		    set error_p 1
		}
		if {[info exists select_btn] && $select_btn ne "" && $choose_file eq ""} {
		    template::form::set_error upload_form choose_file \
			[_ acs-templating.Attach_File_Choose_a_file]
		    set error_p 1
		}
		set share site
#		set f_title ""
#		set f_href ""
		
            if { !$error_p } {
		if {$upload_file ne ""} {

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

		    if {[string match "image/*" $mime_type]} {
			
			image::new \
			    -item_id $item_id \
			    -name ${item_id}_$file_name \
			    -parent_id $parent_id \
			    -title $f_title \
			    -tmp_filename $upload_tmpfile \
			    -creation_user $user_id \
			    -creation_ip [ad_conn peeraddr] \
			    -package_id [ad_conn package_id]
		    } else {
			content::item::new \
			    -item_id $item_id \
			    -name ${item_id}_$file_name \
			    -title $f_title \
			    -parent_id $parent_id \
			    -tmp_filename $upload_tmpfile \
			    -creation_user $user_id \
			    -creation_ip [ad_conn peeraddr] \
			    -package_id [ad_conn package_id] \
			    -mime_type $mime_type
		    }
		    file delete $upload_tmpfile
		    permission::grant \
			-object_id $item_id \
			-party_id $user_id \
			-privilege admin
		    
		    switch -- $share {
			private {
			    permission::set_not_inherit -object_id $item_id
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
		    if {$choose_file ne ""} {
			set item_id $choose_file
			set file_name [lindex [lindex $recent_files_options [util_search_list_of_lists $recent_files_options $item_id 1]] 0]
			# we have to get rid of the icon from the form.
			set file_name [regsub -all {<.*?>} $file_name {}]
		    }
		} 
                set file_name [string trim $file_name]
		if {$f_title eq "" && [info exists file_name]} {
                    set f_title $file_name
		}            
		
		if {$share eq "private" && [string match "image/*" $mime_type]} {
		    # need a private URL that allows viewers of this
		    # object to see the image
		    # this isn't totally secure, because of course
		    # you need to be able to see the image somehow
		    # but we only allow read on the image if you can
		    # see the parent object
		    set f_href "/image/${item_id}/private/${parent_id}/${file_name}"			
		} else {
		    if { [exists_and_not_null f_url] && $url_ok_btn ne "" } {
			set f_href $f_url
		    } else {
			set f_href "/file/${item_id}/${file_name}"
		    }
		}
                element set_value upload_form f_href $f_href
                element set_value upload_form f_title $f_title             
	    }

        }

} else {
    set write_p 0
}

# default to xinha but tinymce will work too. no plugins for rte
set richtextEditor [parameter::get \
			-package_id $package_id \
			-parameter "RichTextEditor" \
			-default "xinha"]

set HTML_UploadTitle ""


if {$richtextEditor eq "xinha"} {
    template::head::add_javascript \
        -src "/resources/acs-templating/xinha-nightly/popups/popup.js"
    template::head::add_javascript \
        -script "
        var selector_window;
	// window.resizeTo(450, 300);

	function attachFileInit() {
	  __dlg_init();

	  var f_href = document.getElementById('f_href');
	  var url = f_href.value;
	  if (url) {
      		onOK();
	      	__dlg_close(null);
	  }

	  var param = window.dialogArguments;
	  if (param) {
 	     if ( typeof param\['f_href'\] != 'undefined' ) {
	        document.getElementById('f_href').value = param\['f_href'\];
	        document.getElementById('f_url').value = param\['f_href'\];
	        document.getElementById('f_title').value = param\['f_title'\];
	     }          
          }	  
	};
	
	function onOK() {
	  var required = {
	    'f_href': '#acs-templating.HTMLArea_NoURL#'
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
	  var fields = \['f_href','f_title', 'f_target'\];
	  var param = new Object();
	  for (var i in fields) {
	    var id = fields\[i\];
	    var el = document.getElementById(id);
	    param\[id\] = el.value;
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
"
}

if {$richtextEditor eq "tinymce"} {
    template::head::add_javascript \
        -src "/resources/acs-templating/tinymce/jscripts/tiny_mce/tiny_mce_popup.js" \
        -order "Z1"
    
    template::head::add_javascript \
        -src "/resources/acs-templating/tinymce/jscripts/tiny_mce/utils/mctabs.js" \
        -order "Z2"
    template::head::add_javascript \
        -src "/resources/acs-templating/tinymce/jscripts/tiny_mce/utils/form_utils.js" \
        -order "Z3"
    template::head::add_javascript \
        -src "/resources/acs-templating/tinymce/jscripts/tiny_mce/utils/validate.js" \
        -order "Z4"
    template::head::add_javascript \
        -src "/resources/acs-templating/tinymce/jscripts/tiny_mce/plugins/oacslink/js/link.js" \
        -order "Z5"
    template::head::add_javascript \
        -order "Z6" \
        -script "
        function attachFileInit() {

          var param = window.dialogArguments;
          // document.getElementById('f_href').focus();
          var f_href = document.getElementById('f_href');
          var url = f_href.value;
          if (url !='') {

                 insertAction();
          }

	  tinyMCEPopup.executeOnLoad('init();');

        }
	function onCancel() {
	    tinyMCEPopup.close();
        }
"
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
"

}
template::add_body_handler \
    -event onload \
    -script "attachFileInit()"
