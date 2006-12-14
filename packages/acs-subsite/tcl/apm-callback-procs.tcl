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

}

ad_proc -private subsite::after_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {
    After upgrade callback for acs-subsite.
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
            5.2.0d1 5.2.0d2 {
		set type_id [content::type::new -content_type "email_image" -pretty_name "Email_Image" \
				 -pretty_plural "Email_Images" -table_name "users_email_image" -id_column "email_image_id"]
		
		set folder_id [content::folder::new -name "Email_Images" -label "Email_Images"]
		
		content::folder::register_content_type -folder_id $folder_id -content_type "email_image" 
		
		
	    }
	    5.2.0a1 5.2.0a2 {
		set value [parameter::get -parameter "AsmForRegisterId" -package_id [subsite::main_site_id]]
		if {[empty_string_p $value]} {
		    apm_parameter_register "AsmForRegisterId" "Assessment used on the registration process." "acs-subsite" "0" "number" "user-login"
		}
		apm_parameter_register "RegImplName" "Name of the implementation used in the registration process" "acs-subsite" "asm_url" "string" "user-login"
		
	    }
	    5.2.0a1 5.2.0a2 {
		set value [parameter::get -parameter "RegistrationId" -package_id [subsite::main_site_id]]
		if {[empty_string_p $value]} {
		    apm_parameter_register "RegistrationId" "Assessment used on the registration process." "acs-subsite" "0" "number" "user-login"
		}
		set value [parameter::get -parameter "RegistrationId" -package_id [subsite::main_site_id]]
		if {[empty_string_p $value]} {
		    apm_parameter_register "RegistrationImplName" "Name of the implementation used in the registration process" "acs-subsite" "asm_url" "string" "user-login"
                }
	    }
	    5.2.0a2 5.2.0a3 {
		db_transaction {
		    db_foreach select_group_name {select group_id, group_name from groups} {
			if { ![empty_string_p [info procs "::lang::util::convert_to_i18n"]] } {
			    set pretty_name [lang::util::convert_to_i18n -message_key "group_title_${group_id}" -text "$group_name"]
			} else {
			    set pretty_name "$group_name"
			}
			
			db_dml title_update "update acs_objects set title=:pretty_name where object_id = :group_id"
		    }
		}
	    }
	    5.2.0a1 5.2.0a2 {
		set value [parameter::get -parameter "RegistrationId" -package_id [subsite::main_site_id]]
		if {[empty_string_p $value]} {
		    apm_parameter_register "RegistrationId" "Assessment used on the registration process." "acs-subsite" "0" "number" "user-login"
		}
		set value [parameter::get -parameter "RegistrationId" -package_id [subsite::main_site_id]]
		if {[empty_string_p $value]} {
		    apm_parameter_register "RegistrationImplName" "Name of the implementation used in the registration process" "acs-subsite" "asm_url" "string" "user-login"
                }
	    }
	    5.2.0a2 5.2.0a3 {
		db_transaction {
		    db_foreach select_group_name {select group_id, group_name from groups} {
			if { ![empty_string_p [info procs "::lang::util::convert_to_i18n"]] } {
			    set pretty_name [lang::util::convert_to_i18n -message_key "group_title_${group_id}" -text "$group_name"]
			} else {
			    set pretty_name "$group_name"
			}
			
			db_dml title_update "update acs_objects set title=:pretty_name where object_id = :group_id"
		    }
		}
	    }
	}
}
