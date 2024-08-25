ad_library {

    Tests for API in tcl/acs-integration-procs.tcl

}

aa_register_case -cats {
    api
    smoke
} -procs {
    ad_return_exception_template
    ad_parse_template
    ad_script_abort
} ad_return_exception_template {
    Test ad_return_exception_template
} {
    set endpoint_name /acs-templating-test-ad-return-exception-template

    set url [acs::test::url]${endpoint_name}

    try {
        ns_register_proc GET $endpoint_name {
            set ::template::parse_level 0
            set errmsg "One custom error"
            set custom_message "One custom message"
            ad_return_exception_template -params {errmsg custom_message} \
                /packages/acs-subsite/lib/shared/db-error
            nsv_incr __acs-templating-test-ad-return-exception-template count
        }

        aa_silence_log_entries -severities {error} {
            set d [ns_http run -method GET $url]
        }

        acs::test::reply_has_status_code $d 500
        aa_false "No code was executed after returning" \
            [nsv_exists __acs-templating-test-ad-return-exception-template count]

        acs::test::reply_contains $d "One custom error"
        acs::test::reply_contains $d "One custom message"
        ns_unregister_op GET $endpoint_name


        ns_register_proc GET $endpoint_name {
            set ::template::parse_level 0
            ad_return_exception_template -status 404 \
                -params {
                    {errmsg "Another custom error"}
                    {custom_message "Another custom message"}
                } \
                /packages/acs-subsite/lib/shared/db-error
            nsv_incr __acs-templating-test-ad-return-exception-template count
        }

        aa_silence_log_entries -severities {error} {
            set d [ns_http run -method GET $url]
        }

        acs::test::reply_has_status_code $d 404
        aa_false "No code was executed after returning" \
            [nsv_exists __acs-templating-test-ad-return-exception-template count]
        acs::test::reply_contains $d "Another custom error"
        acs::test::reply_contains $d "Another custom message"

    } finally {
        ns_unregister_op GET $endpoint_name
    }
}

aa_register_case -cats {
    api
    smoke
} -procs {
    ad_return_template
} ad_return_template {
    Test ad_return_template
} {
    set www_dir [acs_root_dir]/packages/acs-automated-testing/www/

    set user_info [acs::test::user::create -admin]

    try {
        set tcl {
            set msg [ns_queryget msg "A message"]

            nsv_set __test_ad_return_template result \
                [ad_return_template \
                     -string=[ns_queryget string_p 0] \
                     AD-RETURN-TEMPLATE-TEST-[ns_queryget template 1]]
        }
        set wfd [open $www_dir/AD-RETURN-TEMPLATE-TEST.tcl w]
        puts -nonewline $wfd $tcl
        close $wfd

        set adp_1 {
            TEST 1
            @msg@
        }
        set wfd [open $www_dir/AD-RETURN-TEMPLATE-TEST-1.adp w]
        puts -nonewline $wfd $adp_1
        close $wfd

        set adp_2 {
            TEST 2
            @msg@
        }
        set wfd [open $www_dir/AD-RETURN-TEMPLATE-TEST-2.adp w]
        puts -nonewline $wfd $adp_2
        close $wfd

        set request /test/AD-RETURN-TEMPLATE-TEST
        set d [acs::test::http -user_info $user_info $request]
        acs::test::reply_has_status_code $d 200
        acs::test::reply_contains $d "TEST 1"
        acs::test::reply_contains $d "A message"
        aa_equals "Nothing was returned" \
            [nsv_get __test_ad_return_template result] ""

        set request /test/AD-RETURN-TEMPLATE-TEST?template=2&msg=ciao
        set d [acs::test::http -user_info $user_info $request]
        acs::test::reply_has_status_code $d 200
        acs::test::reply_contains $d "TEST 2"
        acs::test::reply_contains $d "ciao"
        aa_equals "Nothing was returned" \
            [nsv_get __test_ad_return_template result] ""

        set request /test/AD-RETURN-TEMPLATE-TEST?template=1&msg=ciao2&string_p=1
        set d [acs::test::http -user_info $user_info $request]
        acs::test::reply_has_status_code $d 200
        acs::test::reply_contains $d "TEST 1"
        acs::test::reply_contains $d "ciao2"
        aa_equals "The page was returned in the nsv" \
            [nsv_get __test_ad_return_template result] [dict get $d body]

    } finally {
        acs::test::user::delete -user_id [dict get $user_info user_id]
        nsv_unset -nocomplain -- __test_ad_return_template
        file delete \
            [acs_root_dir]/packages/acs-automated-testing/www/AD-RETURN-TEMPLATE-TEST-1.adp \
            [acs_root_dir]/packages/acs-automated-testing/www/AD-RETURN-TEMPLATE-TEST-2.adp \
            [acs_root_dir]/packages/acs-automated-testing/www/AD-RETURN-TEMPLATE-TEST.tcl
    }
}
