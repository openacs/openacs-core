ad_library {
    Automated tests.

    @author Joel Aufrecht
    @creation-date 2 Nov 2003
    @cvs-id $Id$
}

aa_register_case -cats {
    api smoke
} -procs {
    apm_higher_version_installed_p
} apm_higher_version_installed_p {
    Test apm_higher_version_installed_p proc.
} {

    aa_run_with_teardown \
        -rollback \
        -test_code {

            set is_lower [apm_higher_version_installed_p acs-admin "1"]
            aa_equals "is the version of acs-admin higher than 0.1d?" $is_lower -1

            set is_higher [apm_higher_version_installed_p acs-admin "1000"]
            aa_equals "is the version of acs-admin lower than 1000.1d?" $is_higher 1

        }
}

aa_register_case -cats {
    api smoke
} -procs {
    acs_admin::check_expired_certificates
    aa_stub
} acs_admin_check_expired_certificates {
    Check acs_admin::check_expired_certificates
} {
    nsv_set __acs_admin_get_expired_certificates email_sent_p false
    aa_stub acs_mail_lite::send {
        nsv_set __acs_admin_get_expired_certificates email_sent_p true
    }

    set expired_certificates_p [::acs_admin::check_expired_certificates]

    if {$expired_certificates_p} {
        aa_true "Expired certificates have been found. Need to send an email." \
            [nsv_get __acs_admin_get_expired_certificates email_sent_p]
    } else {
        aa_false "No expired certificates... Nothing to do." \
            [nsv_get __acs_admin_get_expired_certificates email_sent_p]
    }

    nsv_unset __acs_admin_get_expired_certificates
}

aa_register_case -cats {
    api smoke
} -procs {
    apm_parameter_section_slider
} acs_admin_apm_parameter_section_slider {
    Check apm_parameter_section_slider
} {
    foreach package_key [db_list get_packages {
        select package_key from apm_package_types
    }] {
        set sections [db_list apm_parameter_sections {
            select distinct(section_name)
            from apm_parameters
            where package_key = :package_key
        }]
        if {[llength $sections] <= 1} {
            set right_sections_number 0
        } else {
            set right_sections_number 0
            foreach section $sections {
                if {$section ne ""} {
                    incr right_sections_number
                }
            }
            incr right_sections_number 2
        }
        set proc_sections [lindex [apm_parameter_section_slider $package_key] 0 3]
        aa_true "Sections for '$package_key' are in the right number ([llength $proc_sections] == $right_sections_number)" {[llength $proc_sections] == $right_sections_number}
        foreach section $proc_sections {
            set section_name [lindex $section 0]
            set section_length [llength $section]
            aa_true "Section '$section_name' for '$package_key' is composed by 3 elements ($section_length)" {$section_length == 3}
        }
    }
}

aa_register_case -cats {
    api smoke
} -procs {
    merge::MergeUserInfo
    acs::test::user::create
    acs_user::create_portrait
    acs_user::get_portrait_id
    ad_tmpnam
    permission::grant
    permission::permission_p
} acs_admin_merge_MergeUserInfo {
    Check merge::MergeUserInfo
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {
            # Create 2 dummy users
            set user_id_1 [dict get [acs::test::user::create] user_id]
            set user_id_2 [dict get [acs::test::user::create] user_id]

            # Fake non-image just to have a file to save
            set tmpnam [ad_tmpnam].png
            set wfd [open $tmpnam w]
            puts $wfd [string repeat a 1000]
            close $wfd
            # Give a fake portrait to user_1
            set portrait_id [acs_user::create_portrait \
                                 -user_id $user_id_1 \
                                 -file $tmpnam]
            file delete -- $tmpnam

            # Get a random object none of the two users has write
            # privilege for
            set random_object [db_string get_object {
                select min(object_id) from acs_objects
                where not acs_permission.permission_p(object_id, :user_id_1, 'write')
                  and not acs_permission.permission_p(object_id, :user_id_2, 'write')
            }]
            # Set user_1 as fake creation user
            db_dml update_object {
                update acs_objects set
                creation_user = :user_id_1
                where object_id = :random_object
            }
            # Give user_1 the privilege
            permission::grant -party_id $user_id_1 -object_id $random_object \
                -privilege write

            # Merge them
            merge::MergeUserInfo \
                -from_user_id $user_id_1 \
                -to_user_id $user_id_2

            set portrait_id_2 [acs_user::get_portrait_id -user_id $user_id_2]
            aa_true "Users have now the same portrait ($portrait_id == $portrait_id_2)" \
                {$portrait_id == $portrait_id_2}

            set creation_user_2 [db_string get_creator {
                select creation_user from acs_objects where object_id = :random_object
            }]
            aa_true "Creator of object '$random_object' is now user '$user_id_2'" \
                {$creation_user_2 == $user_id_2}

            aa_true "User '$user_id_2' has now write permission on object '$random_object'" \
                [permission::permission_p \
                     -party_id $user_id_2 \
                     -object_id $random_object \
                     -privilege "write"]
            aa_false "User '$user_id_1' was revoked write permission on object '$random_object'" \
                [permission::permission_p \
                     -party_id $user_id_1 \
                     -object_id $random_object \
                     -privilege "write"]
        }
}

aa_register_case -cats {
    api smoke
} -procs {
    acs_admin::require_site_wide_subsite
    acs_admin::require_site_wide_package
    site_node::get
} acs_admin_require_site_wide {
    Basic check for acs_admin::require_site_wide_subsite and
    acs_admin::require_site_wide_package
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {
            set sws [acs_admin::require_site_wide_subsite]
            set swp [acs_admin::require_site_wide_package -package_key acs-subsite]

            set subsite_name site-wide
            set subsite_parent /acs-admin
            set subsite_path $subsite_parent/$subsite_name
            set node_info [site_node::get -url $subsite_path]

            set node_id [dict get $node_info node_id]
            set subsite_id [dict get $node_info object_id]

            aa_true "Site-wide subsite is where expected" {$subsite_id == $sws}
            aa_true "Site wide package was mounted properly" [db_0or1row check_swa_package {
                select 1 from site_nodes n, apm_packages p
                where n.parent_id = :node_id
                and p.package_id = n.object_id
                and p.package_key = 'acs-subsite'
                and p.package_id = :swp
            }]
        }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
