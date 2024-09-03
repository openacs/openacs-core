ad_library {

    Tests for api in tcl/subsite-procs.tcl

}

aa_register_case -cats {
    api smoke
} -procs {
    subsite::package_keys
    subsite::util::get_package_options
    subsite::get_application_options
    site_node::instantiate_and_mount
    site_node::get_from_object_id
    subsite::get
    subsite::auto_mount_application
    subsite::get_theme_options
    subsite::get_theme
    subsite::get_theme_subsites
    subsite::new_subsite_theme
    subsite::set_theme
    subsite::refresh_theme_subsites
    subsite::delete_subsite_theme
    parameter::get
    parameter::set_value
    subsite::update_subsite_theme
    subsite::get_url
    subsite::util::packages
    util_complete_url_p
    application_group::closest_ancestor_application_group_id
    application_group::closest_ancestor_element
    application_group::closest_ancestor_application_group_site_node
    application_group::group_id_from_package_id
    application_group::package_id_from_group_id
    group::get_element
    group::join_policy
    group::get_join_policy_options
    group::get_members
    application_group::contains_party_p
    group::party_member_p
    group::add_member
    group::remove_member
} subsite_api {
    Test subsite-related API
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {
            set subsite_package_keys [::subsite::package_keys]
            aa_true "Subsite package keys include acs-subsite" {
                "acs-subsite" in $subsite_package_keys
            }

            set subsite_package_options [::subsite::util::get_package_options]
            foreach o $subsite_package_options {
                set o [lindex $o 1]
                aa_true "Option '$o' is found in the subsite packages" {
                    $o in $subsite_package_keys
                }
            }

            set application_package_keys [::subsite::get_application_options]
            aa_log "application_package_keys: $application_package_keys"
            
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

            aa_equals "Subsite and Site Node API return the same result" \
                [lsort -index 0 $subsite_node] \
                [lsort -index 0 [::subsite::get -subsite_id $subsite_id]]


            aa_section {Mount an app underneath the subsite}

            set child_id [::subsite::auto_mount_application \
                              -pretty_name {Test Subsite Child} \
                              -node_id [dict get $subsite_node node_id] \
                              $application_package_key]
            set child_node [::site_node::get_from_object_id -object_id $child_id]


            aa_section {Theme API}

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

            set subsite_theme __test_acs-subsite_theme
            aa_log "Create a test Theme"
            subsite::new_subsite_theme \
                -key $subsite_theme \
                -name "Test ACS Subsite Theme" \
                -template default

            aa_log "Set theme '$subsite_theme' on the test subsite"
            subsite::set_theme -subsite_id $subsite_id -theme $subsite_theme

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

            aa_log "Change a subsite parameter"
            set default_master [::parameter::get -package_id $subsite_id -parameter DefaultMaster]
            ::parameter::set_value -package_id $subsite_id -parameter DefaultMaster -value SomeValue
            set theme_subsites [::subsite::get_theme_subsites -theme $subsite_theme -unmodified]
            aa_false "Theme for subsite '$subsite_id' was modified" {
                $subsite_id in $theme_subsites
            }

            aa_log "Refresh theme subsites for '$subsite_theme'"
            subsite::refresh_theme_subsites -theme $subsite_theme
            aa_equals "Value was not refreshed for modified theme in subsite '$subsite_id'" \
                [::parameter::get -package_id $subsite_id -parameter DefaultMaster] SomeValue

            aa_log "Refresh theme subsites for '$subsite_theme' (including modified)"
            ::subsite::refresh_theme_subsites -theme $subsite_theme -include_modified
            aa_equals "Value was refreshed for modified theme in subsite '$subsite_id'" \
                [::parameter::get -package_id $subsite_id -parameter DefaultMaster] $default_master

            aa_log "Create or replace a theme"
            subsite::new_subsite_theme \
                -key $subsite_theme \
                -name "Test ACS Subsite Theme" \
                -template default \
                -js testjs \
                -create_or_replace
            aa_equals "Value was updated" \
                [db_string q {select js from subsite_themes where key = :subsite_theme}] \
                testjs

            aa_log "Updating a theme"
            subsite::update_subsite_theme \
                -key $subsite_theme \
                -name "Test ACS Subsite Theme" \
                -template default \
                -js testjs2
            aa_equals "Value was updated" \
                [db_string q {select js from subsite_themes where key = :subsite_theme}] \
                testjs2

            subsite::delete_subsite_theme -key $subsite_theme
            aa_false "Theme '$subsite_theme' was deleted" \
                [db_0or1row q {select 1 from subsite_themes where key = :subsite_theme}]


            aa_section {Subsite API}

            set subsite_url [subsite::get_url -node_id [dict get $subsite_node node_id]]
            aa_equals "The subsite URL from API is consistent with the one from the subsite info" \
                $subsite_url [dict get $subsite_node url]

            set absolute_subsite_url [subsite::get_url -node_id [dict get $subsite_node node_id] -absolute_p t]
            aa_true "The URL '$absolute_subsite_url' is actually absolute" \
                [util_complete_url_p $absolute_subsite_url]
            aa_true "Absolute URL ends with the expected relative URL" \
                [regexp ^.*$subsite_url\$ $absolute_subsite_url]

            set application_group_id [db_string get_group {
                select group_id from application_groups
                where package_id = :subsite_id
            }]

            set sub_packages [::subsite::util::packages -node_id [dict get $subsite_node node_id]]
            set app_packages [::subsite::util::packages -node_id [dict get $child_node node_id]]
            set expected_packages [db_list packages {
                select object_id from site_nodes
                where parent_id = (select node_id from site_nodes where object_id = :subsite_id)
            }]
            aa_equals "Packages under this subsite are returned as expected (subsite node)" \
                [lsort $sub_packages] [lsort $expected_packages]
            aa_equals "Packages under this subsite are returned as expected (child node)" \
                [lsort $app_packages] [lsort $expected_packages]


            aa_section {Application Group API}

            set sub_application_group_id [::application_group::closest_ancestor_application_group_id \
                                              -url [dict get $subsite_node url] -include_self]
            aa_equals "Getting application group by URL '[dict get $subsite_node url]' returns expected" \
                $sub_application_group_id $application_group_id

            set sub_application_group_id [::application_group::closest_ancestor_application_group_id \
                                              -node_id [dict get $subsite_node node_id] -include_self]
            aa_equals "Getting application group by node_id '[dict get $subsite_node node_id]' returns expected" \
                $sub_application_group_id $application_group_id

            set sub_application_group_id [::application_group::closest_ancestor_application_group_id \
                                              -url [dict get $child_node url]]
            aa_equals "Getting application group by URL '[dict get $child_node url]' returns expected" \
                $sub_application_group_id $application_group_id

            set sub_application_group_id [::application_group::closest_ancestor_application_group_id \
                                              -node_id [dict get $child_node node_id]]
            aa_equals "Getting application group by node_id '[dict get $child_node node_id]' returns expected" \
                $sub_application_group_id $application_group_id

            aa_equals "Getting application group by package_id '$subsite_id' returns expected" \
                [::application_group::group_id_from_package_id -package_id $subsite_id] $application_group_id

            aa_equals "Getting subsite by application group '$application_group_id' returns expected" \
                [::application_group::package_id_from_group_id -group_id $application_group_id] $subsite_id

            set group_name [db_string get_name {select group_name from groups where group_id = :application_group_id}]
            aa_equals "Group name '$group_name' by db and API is consistent" \
                [::group::get_element -group_id $application_group_id -element group_name] $group_name

            set group_join_policy [db_string get_policy {
                select join_policy from groups where group_id = :application_group_id
            }]
            aa_equals "Group name '$group_name' by db and API is consistent" \
                [::group::join_policy -group_id $application_group_id] $group_join_policy
            aa_equals "Group name '$group_name' by db and API is consistent" \
                [::group::get_element -group_id $application_group_id -element join_policy] $group_join_policy
            set join_policy_options [::group::get_join_policy_options]
            aa_true "Group join policy belongs to one of the options" {
                [lsearch -exact -index 1 $join_policy_options $group_join_policy] >= 0
            }

            set user_id [db_string get_user {select max(user_id) from users}]
            aa_equals "Test subsite membership is empty at first" \
                [::group::get_members -group_id $application_group_id] ""
            aa_false "User '$user_id' is not a member (application group API)" \
                [::application_group::contains_party_p \
                     -package_id $subsite_id \
                     -party_id $user_id]
            aa_false "User '$user_id' is not a member (group API, group)" \
                [::group::party_member_p \
                     -group_id $application_group_id \
                     -party_id $user_id]
            aa_false "User '$user_id' is not a member (group API, group name)" \
                [::group::party_member_p \
                     -group_name $group_name \
                     -party_id $user_id]

            aa_log "Make user '$user_id' member of group '$application_group_id'"
            ::group::add_member -no_perm_check  -group_id $application_group_id -user_id $user_id

            aa_equals "Test subsite membership contains our user" \
                [::group::get_members -group_id $application_group_id] [list $user_id]
            aa_true "User '$user_id' is a member (application group API)" \
                [::application_group::contains_party_p \
                     -package_id $subsite_id \
                     -party_id $user_id]
            aa_true "User '$user_id' is a member (group API, group)" \
                [::group::party_member_p \
                     -group_id $application_group_id \
                     -party_id $user_id]
            aa_true "User '$user_id' is a member (group API, group name)" \
                [::group::party_member_p \
                     -group_name $group_name \
                     -party_id $user_id]

            set possible_member_states [::group::possible_member_states]

            aa_log "Remove user '$user_id' from group '$application_group_id'"
            ::group::remove_member -group_id $application_group_id -user_id $user_id

            aa_equals "Test subsite membership is empty again" \
                [::group::get_members -group_id $application_group_id] ""
            aa_false "User '$user_id' is not a member (application group API)" \
                [::application_group::contains_party_p \
                     -package_id $subsite_id \
                     -party_id $user_id]
            aa_false "User '$user_id' is not a member (group API, group)" \
                [::group::party_member_p \
                     -group_id $application_group_id \
                     -party_id $user_id]
            aa_false "User '$user_id' is not a member (group API, group name)" \
                [::group::party_member_p \
                     -group_name $group_name \
                     -party_id $user_id]

        }
}
