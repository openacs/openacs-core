ad_library {
    Installation procs for email-image management

    @author Miguel Marin (miguelmarin@viaro.net) Viaro Networks (www.viaro.net)
}

namespace eval subsite {}

ad_proc -private subsite::package_install {} {} {
    set type_id [content::type::new -content_type "email_image" -pretty_name "Email_Image" \
		 -pretty_plural "Email_Images" -table_name "users_email_image" -id_column "email_image_id"]

    set folder_id [content::folder::new -name "Email_Images" -label "Email_Images"]

    content::folder::register_content_type -folder_id $folder_id -content_type "email_image" 

    rel_types::new email_image_rel "Email Image" "Email Images" user 0 1 content_item 0 1

}

ad_proc -public subsite::after_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
            5.2.0d2 5.2.0d3 {
		set type_id [content::type::new -content_type "email_image" -pretty_name "Email_Image" \
		     -pretty_plural "Email_Images" -table_name "users_email_image" -id_column "email_image_id"]

		set folder_id [content::folder::new -name "Email_Images" -label "Email_Images"]

		content::folder::register_content_type -folder_id $folder_id -content_type "email_image" 
		
		rel_types::new email_image_rel "Email Image" "Email Images" user 0 1 content_item 0 1
	    }
	}
}

