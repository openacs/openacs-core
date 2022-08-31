ad_library {

    Tests for api in tcl/acs-integration-procs.tcl

}

aa_register_case -cats {
    api
    smoke
} -procs {
    ad_return_exception_template
    ad_parse_template
    ad_script_abort
} ad_return_exception_template {
    Test template::widget::file.

    In particular, we are interested in making sure that it is not
    possible to forge a request so that a form interprets a file that
    already exists on the server as the file the user has uploaded.
} {
    set endpoint_name /acs-templating-test-ad-return-exception-template

    set url [parameter::get \
                 -package_id [apm_package_id_from_key acs-automated-testing] \
                 -parameter TestURL \
                 -default ""]
    if {$url eq ""} {
        set url [ns_conn location]
    }
    set urlInfo [ns_parseurl $url]
    set url ${url}${endpoint_name}

    try {
        ns_register_proc GET $endpoint_name {
            set ::template::parse_level 0
            set errmsg "One custom error"
            set custom_message "One custom message"
            ad_return_exception_template -params {errmsg custom_message} \
                /packages/acs-subsite/lib/shared/db-error
            nsv_incr __acs-templating-test-ad-return-exception-template count
        }

        set d [ns_http run -method GET $url]

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

        set d [ns_http run -method GET $url]

        acs::test::reply_has_status_code $d 404
        aa_false "No code was executed after returning" \
            [nsv_exists __acs-templating-test-ad-return-exception-template count]
        acs::test::reply_contains $d "Another custom error"
        acs::test::reply_contains $d "Another custom message"

    } finally {
        ns_unregister_op GET $endpoint_name
    }
}

