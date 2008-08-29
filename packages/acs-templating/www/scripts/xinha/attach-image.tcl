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

#HAM : ajax sources
set js_source [ah::js_sources]

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

		# check quota
		# FIXME quota is a good idea, set per-user upload quota??
		#            set maximum_folder_size [ad_parameter "MaximumFolderSize"]
		
		#            if { $maximum_folder_size ne "" } {
		#                set max [ad_parameter "MaximumFolderSize"]
		#                if { $folder_size+[file size ${upload_file.tmpfile}] > $max } {
		#                    template::form::set_error upload_form upload_file \
					  #					  [_ file-storage.out_of_space]
		#                   break
		#               }
		#           }	 
		
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
