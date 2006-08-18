ad_page_contract {
    Simple image upload, attach image to object_id passed in, if no
    object_id, use the current package_id
    @author Guenter Ernst guenter.ernst@wu-wien.ac.at, 
    @author Gustaf Neumann neumann@wu-wien.ac.at
    @author Dave Bauer (dave@solutiongrove.com)
    @creation-date 13.07.2004
    @cvs-id $Id$
} {
    {parent_id:integer}
    {selector_type "image"}
}

set f_url ""

set user_id [ad_conn user_id]
# if user has write permission, create image upload form, 
if {[permission::permission_p -party_id $user_id -object_id $parent_id \
	 -privilege "write"]} {

    set write_p 1

    # FIXME DAVEB i18n for share_options
    set share_options [list [list "[_ acs-templating.Only_myself]" private] [list "[_ acs-templating.This_Group]" group] [list "[_ acs-templating.Anyone_on_this_system]" site] [list "[_ acs-templating.Anyone_on_the_internet]" public]]
    ad_form \
        -name upload_form \
        -mode edit \
        -export {selector_type file_types parent_id} \
        -html { enctype multipart/form-data } \
        -form {
            item_id:key
            {upload_file:file(file) {html {size 30}} }
            {share:text(radio),optional {label "[_ acs-templating.This_image_can_be_reused_by]"} {options $share_options} {help_text "[_ acs-templating.This_image_can_be_reused_help]"}}
            {ok_btn:text(submit) {label "[_ acs-templating.HTMLArea_SelectUploadBtn]"}
            }
        } \
        -on_request {
            set share site
        } \
        -on_submit {
            # check file name
            if {$upload_file eq ""} {
                template::form::set_error upload_form upload_file \
                    [_ acs-templating.HTMLArea_SpecifyUploadFilename]
                break
            }

            # check quota
            # FIXME quota is a good idea, set per-user upload quota??
#            set maximum_folder_size [ad_parameter "MaximumFolderSize"]
            
#            if { $maximum_folder_size ne "" } {
#                set max [ad_parameter "MaximumFolderSize"]
#                if { $folder_size+[file size ${upload_file.tmpfile}] > $max } {
#                    template::form::set_error upload_form upload_file \
                        [_ file-storage.out_of_space]
 #                   break
 #               }
 #           }	 
            
            set file_name [template::util::file::get_property filename $upload_file]
            set upload_tmpfile [template::util::file::get_property tmp_filename $upload_file]
            set mime_type [template::util::file::get_property mime_type $upload_file]
            if {$mime_type eq ""} {
                set mime_type [ns_guesstype $file_name] 
            }
            if {$selector_type eq "image" \
                    && ![string match "image/*" $mime_type]} {
                template::form::set_error upload_form upload_file \
                    [_ acs-templating.HTMLArea_SelectImageUploadNoImage]
                break                
            }
            if {[string match "image/*" $mime_type]} {
                
                image::new \
                    -item_id $item_id \
                    -name ${item_id}_$file_name \
                    -parent_id $parent_id \
                    -tmp_filename $upload_tmpfile \
                    -creation_user $user_id \
                    -creation_ip [ad_conn peeraddr] \
                    -package_id [ad_conn package_id]
            } else {
                content::item::new \
                    -item_id $item_id \
                    -name ${item_id}_$file_name \
                    -parent_id $parent_id \
                    -tmp_filename $upload_tmpfile \
                    -creation_user $user_id \
                    -creation_ip [ad_conn peeraddr] \
                    -package_id [ad_conn package_id]
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
            if {$share eq "private"} {
                # need a private URL that allows viewers of this
                # object to see the image
                # this isn't totally secure, because of course
                # you need to be able to see the image somehow
                # but we only allow read on the image if you can
                # see the parent object
                set f_url "/image/$item_id/private/$file_name"
            } else {
                set f_url "/image/$item_id/$file_name"
            }
        }

} else {
    set write_p 0
}

set HTML_Preview "Preview"
set HTML_UploadTitle ""