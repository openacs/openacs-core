ad_library {
    Installation procs for email-image management

    @author Miguel Marin (miguelmarin@viaro.net) Viaro Networks (www.viaro.net)
}

namespace eval subsite {}

ad_proc -private subsite::after_mount {
    {-package_id:required}
    {-node_id:required}
} {
    This is the Tcl proc that is called automatically by the APM
    whenever a new instance of the subsites application is mounted.

    @author Don Baccus (dhogaza@pacifier.com)
    @creation-date 2003-03-05

} {
    subsite::default::create_app_group -package_id $package_id
}

ad_proc -private subsite::package_install {} {} {
    set type_id [content::type::new \
                     -content_type "email_image" -pretty_name "Email_Image" \
                     -pretty_plural "Email_Images" -table_name "users_email_image" \
                     -id_column "email_image_id"]

    set folder_id [content::folder::new -name "Email_Images" -label "Email_Images"]

    content::folder::register_content_type -folder_id $folder_id -content_type "email_image"

}

ad_proc -private subsite::before_uninstantiate {
    {-package_id:required}
} {

    Delete the application group associated with this subsite.

} {
    subsite::default::delete_app_group -package_id $package_id
}

ad_proc -private subsite::before_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {
    Handles upgrade
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
            5.0d3 5.0d4 {
                array set main_site [site_node::get -url /]
                set main_site_id $main_site(package_id)

                # Move parameter values from subsite to kernel

                parameter::set_value \
                    -package_id [ad_acs_kernel_id] \
                    -parameter ApprovalExpirationDays \
                    -value [parameter::get \
                                -package_id $main_site_id \
                                -parameter ApprovalExpirationDays \
                                -default 0]

                parameter::set_value \
                    -package_id [ad_acs_kernel_id] \
                    -parameter PasswordExpirationDays \
                    -value [parameter::get \
                                -package_id $main_site_id \
                                -parameter PasswordExpirationDays \
                                -default 0]


                apm_parameter_unregister \
                    -package_key acs-subsite \
                    -parameter ApprovalExpirationDays \
                    {}

                apm_parameter_unregister \
                    -package_key acs-subsite \
                    -parameter PasswordExpirationDays \
                    {}
            }
        }
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
                set type_id [content::type::new \
                                 -content_type "email_image" -pretty_name "Email_Image" \
                                 -pretty_plural "Email_Images" -table_name "users_email_image" \
                                 -id_column "email_image_id"]

                set folder_id [content::folder::new -name "Email_Images" -label "Email_Images"]

                content::folder::register_content_type \
                    -folder_id $folder_id -content_type "email_image"

            }
            5.2.0a1 5.2.0a2 {
                set value [parameter::get -parameter "AsmForRegisterId" -package_id [subsite::main_site_id]]
                if {$value eq ""} {
                    apm_parameter_register "AsmForRegisterId" "Assessment used on the registration process." "acs-subsite" "0" "number" "user-login"
                }
                apm_parameter_register "RegImplName" "Name of the implementation used in the registration process" "acs-subsite" "asm_url" "string" "user-login"

            }
            5.2.0a1 5.2.0a2 {
                set value [parameter::get -parameter "RegistrationId" -package_id [subsite::main_site_id]]
                if {$value eq ""} {
                    apm_parameter_register "RegistrationId" "Assessment used on the registration process." "acs-subsite" "0" "number" "user-login"
                }
                set value [parameter::get -parameter "RegistrationId" -package_id [subsite::main_site_id]]
                if {$value eq ""} {
                    apm_parameter_register "RegistrationImplName" "Name of the implementation used in the registration process" "acs-subsite" "asm_url" "string" "user-login"
                }
            }
            5.2.0a2 5.2.0a3 {
                db_transaction {
                    db_foreach select_group_name {select group_id, group_name from groups} {
                        if { [info commands "::lang::util::convert_to_i18n"] ne "" } {
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
                if {$value eq ""} {
                    apm_parameter_register "RegistrationId" "Assessment used on the registration process." "acs-subsite" "0" "number" "user-login"
                }
                set value [parameter::get -parameter "RegistrationId" -package_id [subsite::main_site_id]]
                if {$value eq ""} {
                    apm_parameter_register "RegistrationImplName" "Name of the implementation used in the registration process" "acs-subsite" "asm_url" "string" "user-login"
                }
            }
            5.2.0a2 5.2.0a3 {
                db_transaction {
                    db_foreach select_group_name {select group_id, group_name from groups} {
                        if { [info commands "::lang::util::convert_to_i18n"] ne "" } {
                            set pretty_name [lang::util::convert_to_i18n -message_key "group_title_${group_id}" -text "$group_name"]
                        } else {
                            set pretty_name "$group_name"
                        }

                        db_dml title_update "update acs_objects set title=:pretty_name where object_id = :group_id"
                    }
                }
            }
            5.5.0d7 5.5.0d8 {
                db_transaction {
                    set package_keys ([join '[subsite::package_keys]' ,])
                    foreach subsite_id [db_list get_subsite_ids {}] {
                        set new_css [list]
                        set css [parameter::get \
                                    -package_id $subsite_id \
                                    -parameter ThemeCSS \
                                    -default ""]
                        if { $css ne "" } {
                            foreach css $css {
                                lappend new_css [list [list href [lindex $css 0]] \
                                                      [list media [lindex $css 1]]]
                            }
                            parameter::set_value \
                                -package_id $subsite_id \
                                -parameter ThemeCSS \
                                -value $new_css
                        }
                    }
                }
            }
            5.10.0d18 5.10.0d19 {
                if {[db_driverkey ""] eq "postgresql"} {
                    db_transaction {
                        db_foreach table_name {select table_name from acs_object_types} {
                            set table_name_lc [string tolower $table_name]
                            if {$table_name_lc ne $table_name} {
                                ns_log notice "Fix case discrepancy in table_name attribute of acs_object_types: $table_name -> $table_name_lc"
                                db_dml to_lower {update acs_object_types set table_name=:table_name_lc where table_name=:table_name}
                            }
                        }
                    }
                }
            }
            5.10.0d19 5.10.0d20 {
                if {[db_driverkey ""] eq "postgresql"} {
                    db_transaction {
                        db_foreach id_column {select id_column from acs_object_types} {
                            set id_column_lc [string tolower $id_column]
                            if {$id_column_lc ne $id_column} {
                                ns_log notice "Fix case discrepancy in id_column attribute of acs_object_types: $id_column -> $id_column_lc"
                                db_dml to_lower {update acs_object_types set id_column=:id_column_lc where id_column=:id_column}
                            }
                        }
                    }
                }
            }
        }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
