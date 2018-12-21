ad_library {

    Tcl API for email_image store and manipulation

    @author Miguel Marin (miguelmarin@viaro.net) Viaro Networks (www.viaro.net)
}

namespace eval email_image {}


ad_proc -public email_image::update_private_p {
    -user_id:required
    -level:required
} {
    Changes the priv_email field from the users table
    @param user_id
    @param level   Change to this level
} {
    db_transaction {
        db_dml update_users {}
    }
}

ad_proc -private email_image::get_priv_email_from_parameter {
    {-subsite_id ""}
} {
    Returns the priv_email field of the user from the users table.
} {
    if {$subsite_id eq ""} {
        if {[ns_conn isconnected]} {
            set subsite_id [ad_conn subsite_id]
        } else {
            set subsite_id [lindex [apm_package_ids_from_key -package_key acs-subsite -mounted] 0]
        }
    }
    return [parameter::get \
                -package_id $subsite_id \
                -parameter "PrivateEmailLevelP" \
                -default 4]
}


ad_proc -public email_image::get_priv_email {
    -user_id:required
    {-subsite_id ""}
} {
    Returns the priv_email field of the user from the users table.
} {
    set priv_level [db_string get_private_email {}]
    if {$priv_level eq "5"} {
        if {$subsite_id eq ""} {
            if {[ns_conn isconnected]} {
                set subsite_id [ad_conn subsite_id]
            } else {
                set subsite_id [lindex [apm_package_ids_from_key -package_key acs-subsite -mounted] 0]
            }
        }
        set priv_level [email_image::get_priv_email_from_parameter -subsite_id $subsite_id]
    }
    return $priv_level
}

ad_proc -public email_image::get_user_email {
    -user_id:required
    {-return_url ""}
    {-bgcolor "" }
    {-transparent "" }
    {-subsite_id ""}
} {

    Returns the email in different ways (text level 4, image or text
    and image level 3, link level 2, ...)  according to the priv_email
    field in the users table. To create an image the ImageMagick
    software is required, if ImageMagick is not present then the @
    symbol in the email will be shown as an image. When creating an
    image you can choose the background color (In this format
    \#xxxxxx). Also you can make the background color transparent (1
    or 0).

    @param return_url   The url to return when the email is shown as a link
    @param bgcolor      The Background color of the image. Default to \#ffffff
    @param transparent  If the bgcolor is transparent. Default to 1
} {
    set email [email_image::get_email -user_id $user_id]
    set user_level [email_image::get_priv_email -user_id $user_id]
    if { $user_level == 5 } {
        # We get the privacy level from PrivateEmailLevelP parameter
        set priv_level [email_image::get_priv_email_from_parameter -subsite_id $subsite_id]
    } else {
        # We use the privacy level that the user select
        set priv_level $user_level
    }
    set send_email_url [ns_quotehtml "/shared/send-email?sendto=$user_id&return_url=$return_url"]
    switch -- $priv_level {
        "4" {
            return [subst {<a href="mailto:$email" title="#acs-subsite.Send_email_to_this_user#">$email</a>}]
        }
        "3" {
            set email_image_id [email_image::get_related_item_id -user_id $user_id]
            if { $email_image_id != "-1" } {
                # The user has an email image stored in the content repository
                set revision_id [content::item::get_latest_revision -item_id $email_image_id]
                set img_src [ns_quotehtml "/shared/email-image-bits.tcl?user_id=$user_id&revision_id=$revision_id"]
                return [subst {<a href="$send_email_url"><img style="border:0" src="$img_src" alt="#acs-subsite.Email#"></a>}]
            } else {
                # Create a new email_image
                if { [catch { set email_image [email_image::new_item -user_id $user_id -return_url $return_url -bgcolor $bgcolor -transparent $transparent] } errmsg ] } {
                    ns_log Error "email_image::get_user_email failed \n $errmsg"
                    # ImageMagick not present, we protect the email by adding
                    # an image replacing the "@" symbol
                    set email_user [lindex [split $email '@'] 0]
                    set email_domain [lindex [split $email '@'] 1]
                    set email_image [subst {<a href="$send_email_url">$email_user<img style="border:0" src="/shared/images/at.gif" alt="@">$email_domain</a>}]
                }
            }
            return $email_image
        }
        "2" {
            return [subst {<a href="$send_email_url">#acs-subsite.Send_email_to_this_user#</a>}]
        }
        "1" {
            #Do not show e-mail
            return "\#acs-subsite.email_not_available\#"
        }
    }
}


ad_proc -public email_image::get_email {
    -user_id:required
} {
    Returns the email of the user

} {
    return [db_string get_email {}]
}



ad_proc -public email_image::new_item {
    -user_id:required
    {-return_url ""}
    {-bgcolor ""}
    {-transparent ""}
} {
    Creates the email_image of the user with his/her email on it and store it
    in the content repository under the Email_Images folder.

    @param bgcolor       The background color of the image in the format \#xxxxxx, default to \#ffffff
    @param transparent   If you want the background color transparent set it to 1. Default to 1
} {

    # First we create a type and a folder in the content repository
    # with label Email_Images where only items of type email_image
    # will be stored.

    set font_size 14
    set font_type helvetica
    set folder_id [email_image::get_folder_id]
    set email [email_image::get_email -user_id $user_id]
    set image_name "email${user_id}.gif"
    set email_length [string length $email]
    set dest_path "/tmp/$image_name"
    set width [expr {($email_length * ($font_size / 2)) + 2}]
    set height $font_size
    set ypos [expr { ($height / 2) + 3 }]
    set size "${width}x$height"

    if {$bgcolor eq ""} {
        set bgcolor "\#ffffff"
    }

    set bg "xc:$bgcolor"

    # Creating an image of the right length where the email will be
    if {[catch {exec convert -size $size $bg $dest_path} errmsg]} {
        return ""
    }

    # Creating the image with the email of the user on it
    if {[catch {exec convert -font $font_type -fill blue -pointsize $font_size -draw "text 0,$ypos $email" \
                    $dest_path $dest_path} errmsg]} {
        return ""
    }

    if { $transparent eq "" || $transparent eq "1" } {
        # Making the bg color transparent
        if {[catch {exec convert $dest_path -transparent $bgcolor $dest_path} errmsg]} {
            return ""
        }
    }

    # Time to store the image in the content repository
    db_transaction {

        set mime_type [cr_filename_to_mime_type -create $dest_path]
        set creation_ip [ad_conn peeraddr]

        set item_id [content::item::new -name $image_name -parent_id $folder_id -content_type "email_image" \
                         -storage_type "lob" -creation_ip $creation_ip]

        set revision_id [content::revision::new -item_id $item_id -title $image_name -mime_type $mime_type  \
                             -description "User email image"  -creation_ip $creation_ip ]

        email_image::add_relation -user_id $user_id -item_id $item_id
        content::item::set_live_revision -revision_id $revision_id
        db_dml new_lob_content {} -blob_files [list ${dest_path}]
        db_dml lob_size {}
    }

    # Delete the temporary file created by ImageMagick
    catch { file delete -- $dest_path } errMsg

    set img_src [ns_quotehtml "/shared/email-image-bits.tcl?user_id=$user_id&revision_id=$revision_id"]
    set send_email_url [ns_quotehtml "/shared/send-email?sendto=$user_id&return_url=$return_url"]
    set email_image [subst {<a href="$send_email_url"><img style="border:0" src="$img_src" alt="#acs-subsite.Email#"></a>}

    return "$email_image"
}



ad_proc -public email_image::edit_email_image {
    -user_id:required
    -new_email:required
    {-bgcolor ""}
    {-transparent ""}
} {

    Creates a new email_image of the user with his/her new edited
    email on it and store it in the content repository under the
    Email_Images folder. If the user has an image already stored it
    makes a new revision of the image, if not, it creates a new item
    with the new image.

    @param bgcolor       The background color of the image in the format \#xxxxxx, default to \#ffffff
    @param transparent   If you want the background color transparent set it to 1. Default to 1
} {
    if { $new_email == [email_image::get_email -user_id $user_id] } {
        # Email didn't change
        return
    }
    set font_size 14
    set font_type helvetica
    set folder_id [email_image::get_folder_id]
    set image_name "email${user_id}.gif"
    set email_length [string length $new_email]
    set dest_path "/tmp/$image_name"
    set width [expr {($email_length * ($font_size / 2)) + 2}]
    set height $font_size
    set ypos [expr { ($height / 2) + 3 }]
    set size "${width}x$height"

    if {$bgcolor eq ""} {
        set bgcolor "\#ffffff"
    }

    set bg "xc:$bgcolor"

    # Creating an image of the right length where the email will be
    if { [catch { exec convert -size $size $bg $dest_path } ] } {
        # ImageMagick not present
        return
    }

    # Creating the image with the email of the user on it
    exec convert -font $font_type -fill blue -pointsize $font_size -draw "text 0,$ypos $new_email" \
        $dest_path $dest_path

    if { $transparent eq "" || $transparent eq "1" } {
        # Making the bg color transparent
        exec convert $dest_path -transparent $bgcolor $dest_path
    }

    set email_image_id [email_image::get_related_item_id -user_id $user_id]
    set mime_type [cr_filename_to_mime_type -create $dest_path]
    set creation_ip [ad_conn peeraddr]

    if { $email_image_id != "-1" } {
        db_transaction {
            set item_id $email_image_id
            set revision_id [content::revision::new -item_id $item_id -title $image_name \
                                 -mime_type $mime_type  \
                                 -description "User email image" -creation_ip $creation_ip ]
            content::item::set_live_revision -revision_id $revision_id
            db_dml lob_content {} -blob_files [list ${dest_path}]
            db_dml lob_size {}
        }
    } else {
        db_transaction {

            set item_id [content::item::new \
                             -name $image_name -parent_id $folder_id -content_type "email_image" \
                             -storage_type "lob" -creation_ip $creation_ip]

            set revision_id [content::revision::new \
                                 -item_id $item_id -title $image_name -mime_type $mime_type  \
                                 -description "User email image"  -creation_ip $creation_ip ]

            email_image::add_relation -user_id $user_id -item_id $item_id

            db_dml update_cr_items {}
            db_dml lob_content {} -blob_files [list ${dest_path}]
            db_dml lob_size {}
        }
    }
    # Delete the temporary file created by ImageMagick
    catch { file delete -- $dest_path } errMsg
}



ad_proc -public email_image::get_folder_id { } {
    Returns the folder_id of the folder with the name "Email_Images"
} {
    return [db_string check_folder_name {} ]
}

ad_proc -public email_image::add_relation {
    -user_id:required
    -item_id:required
} {
    Add a new relation between user_id and item_id

    @param item_id the item_id of the image in the content repository
} {
    db_exec_plsql add_relation {}
}

ad_proc -public email_image::get_related_item_id {
    -user_id:required
} {
    Returns the item_id of the email_image stored in the content repository for
    user_id.
} {
    return [db_string get_rel_item {} -default -1 ]
}


ad_proc -public email_image::create_type_folder_rel { } {
    Creates a new folder in the content repository with the name and label Email_Images.
    Also create a new type and register this type to the created folder.
    Makes a new relation type to asociate the item_id (email_image in the content repository)
    with the user_id.
} {
    set type_id [content::type::new \
                     -content_type "email_image" -pretty_name "Email_Image" \
                     -pretty_plural "Email_Images" -table_name "users_email_image" \
                     -id_column "email_image_id"]

    set folder_id [content::folder::new -name "Email_Images" -label "Email_Images"]
    content::folder::register_content_type -folder_id $folder_id -content_type "email_image"
    rel_types::new email_image_rel "Email Image" "Email Images" user 0 1 content_item 0 1
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
