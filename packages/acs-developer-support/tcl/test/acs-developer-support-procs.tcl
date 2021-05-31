ad_library {

    Tests for HTTP client API

}

aa_register_case \
    -cats {api smoke} \
    -procs {
        ds_adp_box_class
        ds_adp_file_class
        ds_adp_output_class
        ds_set_adp_reveal_enabled
        ds_adp_reveal_enabled_p
    } \
    ds_adp_reveal_test {
        Check that the adp reveal api works as expected
    } {
        set old_state [ds_adp_reveal_enabled_p]

        try {
            ds_set_adp_reveal_enabled 0
            aa_false "ADP reveal is OFF" [ds_adp_reveal_enabled_p]

            aa_equals "box class is correct" [ds_adp_box_class] developer-support-adp-box-off
            aa_equals "file class is correct" [ds_adp_file_class] developer-support-adp-file-off
            aa_equals "output class is correct" [ds_adp_output_class] developer-support-adp-output-off

            ds_set_adp_reveal_enabled 1
            aa_true "ADP reveal is ON" [ds_adp_reveal_enabled_p]

            aa_equals "box class is correct" [ds_adp_box_class] developer-support-adp-box-on
            aa_equals "file class is correct" [ds_adp_file_class] developer-support-adp-file-on
            aa_equals "output class is correct" [ds_adp_output_class] developer-support-adp-output-on

        } finally {
            ds_set_adp_reveal_enabled $old_state
        }
    }

aa_register_case \
    -cats {api smoke} \
    -procs {
        ds_collection_enabled_p
        ds_database_enabled_p
        ds_enabled_p
        ds_page_fragment_cache_enabled_p
        ds_profiling_enabled_p
        ds_show_p
    } \
    ds_features_enabled_test {
        Check that the api to check for enabled features works as
        expected.
    } {
        set old_enabled_state [ds_enabled_p]
        set old_db_state [ds_database_enabled_p]
        set old_pr_state [ds_profiling_enabled_p]

        try {
            set collection_enabled_p 0
            foreach pattern [nsv_get ds_properties enabled_ips] {
                if { [string match $pattern [ad_conn peeraddr]] } {
                    set collection_enabled_p 1
                    break
                }
            }
            aa_equals "collection enabled value is correct" \
                $collection_enabled_p [ds_collection_enabled_p]

            ds_set_database_enabled 0
            aa_equals "database enabled is OFF" \
                0 [ds_database_enabled_p]
            ds_set_database_enabled 1
            aa_equals "database enabled is ON" \
                1 [ds_database_enabled_p]

            aa_equals "page fragment cache enabled value is correct" \
                [nsv_get ds_properties page_fragment_cache_p] \
                [ds_page_fragment_cache_enabled_p]

            ds_set_profiling_enabled 0
            aa_equals "profiling enabled is OFF" \
                0 [ds_profiling_enabled_p]
            ds_set_profiling_enabled 1
            aa_equals "profiling enabled is ON" \
                1 [ds_profiling_enabled_p]

            set enabled_p 0
            nsv_set ds_properties enabled_p $enabled_p
            set ::ds_enabled_p $enabled_p
            aa_equals "enabled value is OFF" 0 [ds_enabled_p]
            aa_equals "show value is OFF" 0 [ds_show_p]

            set enabled_p 1
            nsv_set ds_properties enabled_p $enabled_p
            set ::ds_enabled_p $enabled_p
            aa_equals "enabled value is ON" 1 [ds_enabled_p]
            aa_equals "show value is the permission enabled value" [ds_permission_p] [ds_show_p]

        } finally {
            ds_set_database_enabled $old_db_state
            ds_set_profiling_enabled $old_pr_state
            nsv_set ds_properties enabled_p $old_enabled_state
            set ::ds_enabled_p $old_enabled_state
        }
    }
