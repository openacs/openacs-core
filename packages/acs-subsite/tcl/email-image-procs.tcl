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
    @user_id 
    @level   Change to this level
} {
    db_transaction {
	db_dml update_users { *SQL* }
    }
}

ad_proc -public email_image::get_priv_email {
    -user_id:required
} {
    Returns the priv_email field of the user from the users table.
    @user_id
} {
    return [db_string get_private_email { *SQL* }]
}


ad_proc -public email_image::check_image_magick {} {
    Check if the ImageMagick software is installed and if the necesary
    library (FreeType) is present, by looking for the "convert" command and
    freetype library.
    
    returns 1 if required software is present, 0 otherwise
} {
    set convert_p [string length [exec find /usr/local/bin -name convert]]
    set freetype_p [string length [exec whereis freetype]]
    if { $convert_p != 0 && $freetype_p != 0 } {
	return 1
    } else {
	return 0
    }
}



ad_proc -public email_image::get_user_email {
    -user_id:required
    {-return_url ""}
    {-bgcolor "" }
    {-transparent "" }
} {
    Returns the email in differnet diferent ways (text level 4, image or text and image level 3, link level 2, ...)
    according to the priv_email field in the users table. To create an image the ImageMagick software is required, 
    if ImageMagick is not present then the @ symbol in the email will be shown as an image. When creating an image 
    you can choose the background color (In this format \#xxxxxx). Also you can make the background color transparent 
    (1 or 0).
    
    @user_id
    @return_url   The url to return when the email is shown as a link
    @bgcolor      The Background color of the image. Default to \#ffffff
    @transparent  If the bgcolor is transparent. Default to 1
} {
    set email [email_image::get_email -user_id $user_id]
    set user_level [email_image::get_priv_email -user_id $user_id]
    if { $user_level == 5 } {
	# We get the privacy level from PrivateEmailLevelP parameter
	set priv_level [parameter::get_from_package_key -package_key "acs-subsite" \
			    -parameter "PrivateEmailLevelP" -default 4]
    } else {
	# We use the privacy level that the user select
	set priv_level $user_level
    }
    switch $priv_level {
	"4" {
	    return "<a href=mailto:$email title=\"Send email to this user\">$email</a>"
	}
	"3" {
	    if { [email_image::check_image_magick] } {
		set email_image_id [email_image::get_related_item_id -user_id $user_id]
		if { $email_image_id != "-1" } {
		    # The user has an email image stored in the content repository
		    set revision_id [content::item::get_latest_revision -item_id $email_image_id]
		    set export_vars "user_id=$user_id&revision_id=$revision_id"
		    set email_image "<a href=\"/shared/send-email?sendto=$user_id&return_url=$return_url\">\
                                     <img border=0 align=middle src=/shared/email-image-bits.tcl?$export_vars></a>"
    
		} else {
		    # Create a new email_image
		    set email_image [email_image::new_item -user_id $user_id -bgcolor $bgcolor -transparent $transparent]
		}
	    } else {
		# ImageMagick not present, we protect the email by adding
		# an image replacing the "@" symbol
		set email_user [lindex [split $email '@'] 0]
		set email_domain [lindex [split $email '@'] 1]
		set email_image "<a href=\"/shared/send-email?sendto=$user_id&return_url=$return_url\">${email_user}\
                                 <img border=0 align=middle src=/shared/images/at.gif>${email_domain}</a>"
	    }
	    return $email_image
	}
	"2" {
	    return "<a href=\"/shared/send-email?sendto=$user_id&return_url=$return_url\">\
                            \#acs-subsite.Send_email_to_this_user\#</a>"
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

    @user_id
} {
    return [db_string get_email { *SQL* }]
}



ad_proc -public email_image::new_item {
    -user_id:required
    {-bgcolor ""}
    {-transparent ""}
} {
    Creates the email_image of the user with his/her email on it and store it
    in the content repository under the Email_Images folder.

    @user_id       
    @bgcolor       The background color of the image in the format \#xxxxxx, default to \#ffffff
    @transparent   If you want the background color transparent set it to 1. Default to 1
} {
    
    # First we create a type and a folder in the content repository 
    # with label Email_Images where only items of type email_image 
    # will be stored.
	
    set folder_id [email_image::get_folder_id]
    set email [email_image::get_email -user_id $user_id]
    set image_name "email${user_id}.gif"
    set email_length [string length $email]
    set dest_path "/tmp/$image_name"
    set width [expr $email_length * 10]
    set size "${width}x20"

    if { [string equal $bgcolor ""]} {
	set bgcolor "\#ffffff"
    }

    set bg "xc:$bgcolor"
    
    # Creating an image of the rigth length where the email will be
    exec convert -size $size $bg $dest_path
    
    # Creating the image with the email of the user on it
    exec convert -font helvetica -fill blue -pointsize 16 -draw "text 1,15 $email" \
	$dest_path $dest_path

    if { [string equal $transparent ""] || [string equal $transparent "1"] } {
	# Making the bg color transparent
	exec convert $dest_path -transparent $bgcolor $dest_path
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
	db_dml update_cr_items { *SQL* }
	db_dml lob_content { *SQL* } -blob_files [list ${dest_path}]
	db_dml lob_size { *SQL* }
    }
    
    # Delete the temporary file created by ImageMagick
    catch { file delete  $dest_path } errMsg
    
    set export_vars "user_id=$user_id&revision_id=$revision_id"
    set email_image "<a href=\"/shared/send-email?sendto=$user_id\"><img align=middle border=0 \
                     src=/shared/email-image-bits.tcl?$export_vars></a>"

    return "$email_image"
}



ad_proc -public email_image::edit_email_image {
    -user_id:required
    -new_email:required
    {-bgcolor ""}
    {-transparent ""}
} {
    Creates a new email_image of the user with his/her new edited email on it and store it
    in the content repository under the Email_Images folder. If the user has an image already
    stored it makes a new revision of the image, if not, it creates a new item with the new
    image.

    @user_id       
    @bgcolor       The background color of the image in the format \#xxxxxx, default to \#ffffff
    @transparent   If you want the background color transparent set it to 1. Default to 1
} {
    
    if { ![email_image::check_image_magick]} {
	# ImageMagick or library not present
	return
    }
    if { $new_email == [email_image::get_email -user_id $user_id] } {
	# Email didn't change
	return
    }
    set folder_id [email_image::get_folder_id]
    set image_name "email${user_id}.gif"
    set email_length [string length $new_email]
    set dest_path "/tmp/$image_name"
    set width [expr $email_length * 10]
    set size "${width}x20"

    if { [string equal $bgcolor ""]} {
	set bgcolor "\#ffffff"
    }

    set bg "xc:$bgcolor"
    
    # Creating an image of the rigth length where the email will be
    exec convert -size $size $bg $dest_path
    
    # Creating the image with the email of the user on it
    exec convert -font helvetica -fill blue -pointsize 16 -draw "text 1,15 $new_email" \
	$dest_path $dest_path

    if { [string equal $transparent ""] || [string equal $transparent "1"] } {
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
	    db_dml update_cr_items { *SQL* }
	    db_dml lob_content { *SQL* } -blob_files [list ${dest_path}]
	    db_dml lob_size { *SQL* }
	}
    } else {
	db_transaction {
	    
	    set item_id [content::item::new -name $image_name -parent_id $folder_id -content_type "email_image" \
			     -storage_type "lob" -creation_ip $creation_ip]
	    
	    set revision_id [content::revision::new -item_id $item_id -title $image_name -mime_type $mime_type  \
				 -description "User email image"  -creation_ip $creation_ip ]

	    email_image::add_relation -user_id $user_id -item_id $item_id

	    db_dml update_cr_items { *SQL* }
	    db_dml lob_content { *SQL* } -blob_files [list ${dest_path}]
	    db_dml lob_size { *SQL* }
	}
    }
    # Delete the temporary file created by ImageMagick
    catch { file delete  $dest_path } errMsg
}



ad_proc -public email_image::get_folder_id { } {
    Returns the folder_id of the folder with the name "Email_Images"
} {
    return [db_string check_folder_name { *SQL* } ]
}

ad_proc -public email_image::add_relation {
    -user_id:required
    -item_id:required
} {
    Add a new relation between user_id and item_id
    @user_id
    @item_id the item_id of the image in the content repository
} {
    db_exec_plsql add_relation { *SQL* }
}

ad_proc -public email_image::get_related_item_id {
    -user_id:required
} {
    Returns the item_id of the email_image stored in the content repository for
    user_id.
    @user_id
} {
    return [db_string get_rel_item { *SQL* } -default -1 ]
}


ad_proc -public email_image::create_type_folder_rel { } {
    Creates a new folder in the content repository with the name and label Email_Images.
    Also create a new type and register this type to the created folder.
    Makes a new relation type to asociate the item_id (email_image in the content repository) 
    with the user_id.
} {
    set type_id [content::type::new -content_type "email_image" -pretty_name "Email_Image" \
		 -pretty_plural "Email_Images" -table_name "users_email_image" -id_column "email_image_id"]

    set folder_id [content::folder::new -name "Email_Images" -label "Email_Images"]

    content::folder::register_content_type -folder_id $folder_id -content_type "email_image" 

    rel_types::new email_image_rel "Email Image" "Email Images" user 0 1 content_item 0 1
}
