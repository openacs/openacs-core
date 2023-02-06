ad_library {

    Tests for api in tcl/subsite-procs.tcl

}

aa_register_case -cats {
    api smoke
} -procs {
    subsite::package_keys
    subsite::get_application_options
    site_node::instantiate_and_mount
    site_node::get_from_object_id
    subsite::auto_mount_application
    subsite::get_theme_options
    subsite::get_theme
} subsite_api {
    Test subsite-related api
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {
            set subsite_package_keys [::subsite::package_keys]
            aa_true "Subsite package keys include acs-subsite" {
                "acs-subsite" in $subsite_package_keys
            }

            set application_package_keys [::subsite::get_application_options]
            aa_true "Application package keys include the search package" {
                [lsearch -index 1 -exact $application_package_keys search] >= 0
            }
            set application_package_key [lindex $application_package_keys 0 1]

            aa_section {Create test subsite}
            set package_key [lindex $subsite_package_keys 0]
            set subsite_id [::site_node::instantiate_and_mount \
                                -node_name __test_acs-subsite \
                                -package_name {acs-subsite Test Subsite} \
                                -package_key $package_key]
            set subsite_node [::site_node::get_from_object_id -object_id $subsite_id]

            aa_section {Create a sub test subsite}
            set child_id [::subsite::auto_mount_application \
                              -pretty_name {Test Subsite Child} \
                              -node_id [dict get $subsite_node node_id] \
                              $application_package_key]
            set child_node [::site_node::get_from_object_id -object_id $child_id]

            set subsite_theme [::subsite::get_theme -subsite_id $subsite_id]
            set theme_options [::subsite::get_theme_options]
            aa_true "Theme '$subsite_theme' belongs to the theme options" {
                [lsearch -index 1 -exact $theme_options $subsite_theme] >= 0
            }

            set theme_subsites [::subsite::get_theme_subsites -theme $subsite_theme]
            aa_true "Subsite '$subsite_id' is among those using theme '$subsite_theme'" {
                $subsite_id in $theme_subsites
            }
            set theme_subsites [::subsite::get_theme_subsites -theme $subsite_theme -unmodified]
            aa_true "Subsite '$subsite_id' is among those using theme '$subsite_theme' (unmodified)" {
                $subsite_id in $theme_subsites
            }

        }
}
