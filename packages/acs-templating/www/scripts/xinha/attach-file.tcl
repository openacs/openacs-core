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

		if {$f_title eq "" && [info exists file_name]} {
		    element set_value upload_form f_title $file_name
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
	    }
	    element set_value upload_form f_href $f_href
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