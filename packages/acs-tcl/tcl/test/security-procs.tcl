ad_library {

    Test api defined in tcl/security-procs.tcl

}

aa_register_case \
    -cats { api } \
    -procs {
        ad_change_password
        ad_check_password
    } \
    ad_change_check_password {
        Test checking and changing the password.
    } {
        set user [acs::test::user::create]
        set user_id  [dict get $user user_id]
        set password [dict get $user password]

        try {

            aa_true "Old password is correct" [ad_check_password $user_id $password]

            aa_log "Change password"
            ad_change_password \
                $user_id \
                ABCD

            aa_true "New password is correct" [ad_check_password $user_id ABCD]

        } finally {
            acs::test::user::delete -user_id $user_id
        }
    }

aa_register_case \
    -cats { api } \
    -procs {
        ad_get_login_url
        ad_get_logout_url
        ad_return_url
    } \
    login_logout_urls {

        Test generation of login and logout URLs via the API

    } {
        set return_url [ad_return_url]


        aa_section {Login URL}

        db_foreach get_user_info {
            select username, authority_id
            from users
            fetch first 10 rows only
        } {
            set login_url [ad_get_login_url -authority_id $authority_id -username $username]
            aa_true "Login URL '$login_url' is a local URL" [util_url_valid_p -relative $login_url]
            aa_false "Login URL '$login_url' is not external" [util::external_url_p $login_url]

            set login_url [ad_get_login_url -authority_id $authority_id -username $username -return]
            aa_true "Login URL '$login_url' is a local URL" [util_url_valid_p -relative $login_url]
            aa_false "Login URL '$login_url' is not external" [util::external_url_p $login_url]
            aa_true "Login URL '$login_url' contains the return URL" {
                [string first [ns_urlencode $return_url] $login_url] >= 0
            }
        }


        aa_section {Logout URL}

        set logout_url [ad_get_logout_url]
        aa_true "Logout URL '$logout_url' is a local URL" [util_url_valid_p -relative $logout_url]
        aa_false "Logout URL '$logout_url' is not external" [util::external_url_p $logout_url]

        set logout_url [ad_get_logout_url -return]
        aa_true "Logout URL '$logout_url' is a local URL" [util_url_valid_p -relative $logout_url]
        aa_false "Logout URL '$logout_url' is not external" [util::external_url_p $logout_url]
        aa_true "Logout URL '$logout_url' contains the return URL" {
            [string first [ns_urlencode $return_url] $logout_url] >= 0
        }

        set logout_url [ad_get_logout_url -return -return_url __test__return__url]
        aa_true "Logout URL '$logout_url' is a local URL" [util_url_valid_p -relative $logout_url]
        aa_false "Logout URL '$logout_url' is not external" [util::external_url_p $logout_url]
        aa_true "Logout URL '$logout_url' contains the return URL" {
            [string first [ns_urlencode __test__return__url] $logout_url] >= 0
        }

        try {

            set test_url acs-tcl-test-security-procs-login-logout-url
            ns_register_proc GET $test_url {
                if {[ad_conn user_id] == 0} {
                    ns_return 403 text/plain Forbidden
                } else {
                    ns_return 200 text/plain OK
                }
            }

            set user_info [::acs::test::user::create]
            set user_id [dict get $user_info user_id]
            set d [::acs::test::login $user_info]

            aa_log "Requesting test endpoint as logged-in user"
            set d [acs::test::http -last_request $d /$test_url]
            acs::test::reply_has_status_code $d 200

            aa_log "Call the logout URL"
            set d [acs::test::http -last_request $d $logout_url]

            aa_log "Requesting test endpoint as logged out"
            set d [acs::test::http -last_request $d /$test_url]
            acs::test::reply_has_status_code $d 403

        } finally {
            ns_unregister_op GET $test_url
            acs::test::user::delete -user_id $user_id
        }

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

        Test the use case of logging-out a user from everywhere by
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

                set url [acs::test::url]/${test_url}

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
                aa_silence_log_entries -severities warning {
                    # Warning: downgrade login_level of user ... since there is no login cookie provided
                    set r [ns_http run -headers $headers -method GET $url]
                }
                aa_equals "I should now NOT be authenticated" [dict get $r status] 403
            } \
            -teardown_code {
                # Fix my login
                ad_user_login $user_id
                ns_unregister_op GET $test_url
            }
    }

aa_register_case \
    -cats { api } \
    -procs {
        security::safe_tmpfile_p
        ad_opentmpfile
        acs_root_dir
        ad_file
    } \
    safe_tmpfile_p {

        Test security::safe_tmpfile_p proc

    } {
        #
        # ad_tmpnam is currently not deprecated, but might be in the
        # future, so we generate temporary filenames "manually"
        #

        set tmpfile [ns_config ns/parameters tmpdir]/afile
        aa_section {Path to a tmpfile that does not exist yet}
        aa_true "A temporary filename is safe" [security::safe_tmpfile_p $tmpfile]

        set tmpfile [ns_config ns/parameters tmpdir]/afile-2
        aa_section {Path to a tmpfile that we demand to exist}
        aa_false "A temporary filename is not safe if the file des not exist" \
           [security::safe_tmpfile_p -must_exist $tmpfile]

        aa_section {Path to an existing tmpfile}
        set F [ad_opentmpfile tmpfile]
        puts $F 1234
        close $F
        aa_true "An existing tmpfile is safe" [security::safe_tmpfile_p -must_exist $tmpfile]
        ad_file delete $tmpfile

        aa_section {Path to a tmpfile in a folder of the tmpdir}
        set tmpfile [ns_config ns/parameters tmpdir]/afolder/test
        aa_false "A safe tmpfile can only be a direct child of the tmpdir" \
           [security::safe_tmpfile_p $tmpfile]

        aa_section {Trying to confuse the proc with ".."}
        set tmpfile [ns_config ns/parameters tmpdir]/afolder/../../test
        aa_false "Proc is not fooled by .." \
           [security::safe_tmpfile_p $tmpfile]

        aa_section {Trying to confuse the proc with "~"}
        set tmpfile ~/../../test
        aa_false "Proc is not fooled by ~" \
           [security::safe_tmpfile_p $tmpfile]

        aa_section {Path to a file outside of the tmpdir}
        set tmpfile [acs_root_dir]/mypreciouscode
        aa_false "A safe tmpfile can only be a direct child of the tmpdir" \
           [security::safe_tmpfile_p $tmpfile]

    }
