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
        ds_init
    } \
    ds_features_enabled_test {
        Check that the API to check for enabled features works as
        expected.
    } {
        aa_log "Init variables"
        ds_init
        aa_true "Init worked correctly" {
            ![ds_enabled_p] ||
            (
             (![ds_collection_enabled_p] ||
              ([info exists ::ds_collection_enabled_p] && $::ds_collection_enabled_p == 1)) &&
             (![ds_profiling_enabled_p] ||
              ([info exists ::ds_profiling_enabled_p] && $::ds_profiling_enabled_p == 1)) &&
             (![ds_show_p] ||
              ([info exists ::ds_show_p] && $::ds_show_p == 1))
             )
        }

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
            aa_true "collection enabled value is correct" {
                ($collection_enabled_p && [ds_collection_enabled_p]) ||
                (!$collection_enabled_p && ![ds_collection_enabled_p])
            }

            ds_set_database_enabled 0
            aa_false "database enabled is OFF" \
                [ds_database_enabled_p]
            ds_set_database_enabled 1
            aa_true "database enabled is ON" \
                [ds_database_enabled_p]

            aa_true "page fragment cache enabled value is correct" {
                ([nsv_get ds_properties page_fragment_cache_p] && [ds_page_fragment_cache_enabled_p]) ||
                (![nsv_get ds_properties page_fragment_cache_p] && ![ds_page_fragment_cache_enabled_p])
            }

            ds_set_profiling_enabled 0
            aa_false "profiling enabled is OFF" \
                [ds_profiling_enabled_p]
            ds_set_profiling_enabled 1
            aa_true "profiling enabled is ON" \
                [ds_profiling_enabled_p]

            set enabled_p 0
            nsv_set ds_properties enabled_p $enabled_p
            set ::ds_enabled_p $enabled_p
            aa_false "enabled value is OFF" [ds_enabled_p]
            aa_false "show value is OFF" [ds_show_p]

            set enabled_p 1
            nsv_set ds_properties enabled_p $enabled_p
            set ::ds_enabled_p $enabled_p
            aa_true "enabled value is ON" [ds_enabled_p]
            aa_true "show value is the permission enabled value" {
                ([ds_permission_p] && [ds_show_p]) ||
                (![ds_permission_p] && ![ds_show_p])
            }

        } finally {
            ds_set_database_enabled $old_db_state
            ds_set_profiling_enabled $old_pr_state
            nsv_set ds_properties enabled_p $old_enabled_state
            set ::ds_enabled_p $old_enabled_state
        }
    }

aa_register_case \
    -cats {api smoke} \
    -procs {
        ds_add
        ds_comment
        ds_collect_db_call
        ds_profile
    } \
    ds_add_test {
        Check that the API to add content to the report works as
        expected.
    } {
        set old_enabled_state [ds_enabled_p]
        set old_db_state [ds_database_enabled_p]

        try {
            set collection_enabled_p [ds_collection_enabled_p]

            set enabled_p 0
            nsv_set ds_properties enabled_p $enabled_p
            set ::ds_enabled_p $enabled_p

            set key    $::ad_conn(request).comment
            set db_key $::ad_conn(request).db
            set pr_key $::ad_conn(request).prof

            nsv_set ds_request $key ""
            set current_size 0

            ds_add comment __test
            set size_new [llength [nsv_get ds_request $key]]

            aa_true "DS is disabled, adding should not have effect" {$current_size == $size_new}

            aa_true "DS is disabled, profiling fails" [catch {ds_profile start __test}]
            aa_true "Profiling fails on invalid command" [catch {ds_profile __test __test}]

            nsv_set ds_request $key [list]
            set current_size 0

            aa_log "enabling DS"
            set enabled_p 1
            nsv_set ds_properties enabled_p $enabled_p
            set ::ds_enabled_p $enabled_p

            aa_log "start profiling"
            ds_profile start __test
            aa_true "Profiling fails on invalid command" [catch {ds_profile __test __test}]

            aa_true "DS is enabled, profiling started correctly" {
                [info exists ::ds_profile__start_clock(__test)] &&
                $::ds_profile__start_clock(__test) ne ""
            }

            aa_log "stopping profiling"
            ds_profile stop __test
            aa_true "DS is enabled, profiling stopped correctly" {[llength [nsv_get ds_request $pr_key]] == 2}

            aa_log "Adding stuff to the report"
            ds_add comment __test
            ds_comment __test

            set db_current_size [expr {[nsv_exists ds_request $db_key] ?
                                   [llength [nsv_get ds_request $db_key]] : 0}]
            aa_log "disable database stats collection"
            ds_set_database_enabled 0
            aa_log "issuing a query"
            db_string query {select 1 from dual}
            set db_size_new [expr {[nsv_exists ds_request $db_key] ?
                                   [llength [nsv_get ds_request $db_key]] : 0}]
            aa_log $db_size_new

            aa_true "DB stat collection is disabled, db stat collection should not have effect" \
                {$db_current_size == $db_size_new}

            aa_log "enabled database stats collection"
            ds_set_database_enabled 1
            set db_current_size [expr {[nsv_exists ds_request $db_key] ?
                                       [llength [nsv_get ds_request $db_key]] : 0}]
            aa_log "issuing a query"
            db_string query {select 1 from dual}

            set db_size_new [llength [nsv_get ds_request $db_key]]

            if {$collection_enabled_p} {
                aa_true "Collection is enabled, db stat collection should work" \
                    {$db_current_size < $db_size_new}
            } else {
                aa_true "Collection is disabled, db stat collection should not have effect" \
                    {$db_current_size == $db_size_new}
            }

            set size_new [llength [nsv_get ds_request $key]]

            if {$collection_enabled_p} {
                aa_true "Collection is enabled, adding should work" \
                    {$current_size + 2 == $size_new}
            } else {
                aa_true "Collection is disabled, adding should not have effect" \
                    {$current_size == $size_new}
            }

        } finally {
            nsv_set ds_properties enabled_p $old_enabled_state
            set ::ds_enabled_p $old_enabled_state

            ds_set_database_enabled $old_db_state
        }
    }

aa_register_case \
    -cats {api smoke} \
    -procs {
        ds_link
    } \
    ds_link_test {
        Check that ds_link works as expected
    } {
        set old_enabled_state [ds_enabled_p]
        set old_user_switching [ds_user_switching_enabled_p]

        set permission_p [ds_permission_p]
        set collection_enabled_p [ds_collection_enabled_p]

        try {
            ds_set_user_switching_enabled 0
            set enabled_p 0
            nsv_set ds_properties enabled_p $enabled_p
            set ::ds_enabled_p $enabled_p

            aa_equals "No DS and no user switch, link is empty" [ds_link] ""

            ds_set_user_switching_enabled 1
            aa_true "No DS and user switch, link is empty if no permissions" \
                {!$permission_p || [ad_looks_like_html_p [ds_link]]}

            set enabled_p 1
            nsv_set ds_properties enabled_p $enabled_p
            set ::ds_enabled_p $enabled_p

            aa_true \
                "DS enabled, link will contain the DS URL and look as HTML if collection is enabled" \
                {
                    !$collection_enabled_p ||
                    ([ad_looks_like_html_p [ds_link]] &&
                     [string first [ds_support_url] [ds_link]] >= 0)
                }

        } finally {
            nsv_set ds_properties enabled_p $old_enabled_state
            set ::ds_enabled_p $old_enabled_state

            ds_set_user_switching_enabled $old_user_switching
        }

    }
