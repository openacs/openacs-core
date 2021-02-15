ad_library {

    Test api defined in tcl/security-procs.tcl

}

aa_register_case \
    -cats { api } \
    -procs {
        ad_user_login
        apm_package_id_from_key
        parameter::get
        sec_change_user_auth_token
    } \
    logout_from_everywhere {

        Test the use case of loggin out a user from everywhere by
        changing its own authentication token (e.g. when password is
        changed).

    } {
        set user_id [ad_conn user_id]

        aa_run_with_teardown \
            -test_code {
                set test_url acs-tcl-test-security-procs-logout-from-everywhere
                ns_register_proc GET $test_url {
                    if {[ad_conn user_id] == 0} {
                        ns_return 403 text/plain Forbidden
                    } else {
                        ns_return 200 text/plain OK
                    }
                }

                #
                # Check, if a testURL was specified in the config file
                #
                # ns_section ns/server/${server}/acs/acs-automated-testing
                #         ns_param TestURL http://127.0.0.1:8080/
                #
                set url [parameter::get \
                             -package_id [apm_package_id_from_key acs-automated-testing] \
                             -parameter TestURL  -default ""]
                if {$url eq ""} {
                    set url [ns_conn location]
                }
                set url "$url/$test_url"

                # This test strictly requires a cookie-based
                # authentication, and not e.g. a test authentication
                # such as that we obtain via acs::test::login. A user
                # agent relying on such test authentication (e.g. in a
                # continuous integration pipeline) would fail this
                # test. Let's forge one: login the current user so
                # that cookies are set, retrieve such cookies and set
                # them as headers of the next HTTP request.
                # set headers [ns_conn headers]
                set headers [ns_set create]
                ad_user_login $user_id
                set cookies [list]
                foreach cookie {
                    ad_session_id
                    ad_user_login
                    ad_user_login_secure
                    ad_secure_token
                } {
                    set cookie_value [ns_getcookie -include_set_cookies true -- $cookie ""]
                    if {$cookie_value ne ""} {
                        lappend cookies $cookie=\"${cookie_value}\"
                    }
                }
                if {[llength $cookies] > 0} {
                    ns_set put $headers cookie [join $cookies "; "]
                }

                aa_section "Request the page as myself"
                set r [ns_http run -headers $headers -method GET $url]
                aa_equals "I should now be authenticated" [dict get $r status] 200

                aa_section "Change the authentication token"
                sec_change_user_auth_token $user_id

                aa_section "Check again if my login works"
                set r [ns_http run -headers $headers -method GET $url]
                aa_equals "I should now NOT be authenticated" [dict get $r status] 403
            } \
            -teardown_code {
                # Fix my login
                ad_user_login $user_id
                ns_unregister_op GET $test_url
            }
    }
