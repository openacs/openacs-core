ad_library {

    Automated tests for procs in tcl/authentication-procs.tcl

}

aa_register_case \
    -cats {api} \
    -procs {
        auth::can_admin_system_without_authority_p
    } \
    auth__can_admin_system_without_authority_p {
        Test auth::can_admin_system_without_authority_p
    } {
        aa_run_with_teardown \
            -rollback \
            -test_code {

                set authorities [db_list get_authorities {
                    select authority_id from auth_authorities
                }]

                # First make sure that proc returns the expected value
                # in any setup...
                foreach authority_id $authorities {
                    set expected [db_0or1row admins_left_p {
                        select 1 from dual where exists
                        (
                          select 1
                          from acs_permissions p,
                             party_approved_member_map m,
                             acs_magic_objects amo,
                             cc_users u
                          where amo.name = 'security_context_root'
                          and p.object_id = amo.object_id
                          and p.grantee_id = m.party_id
                          and u.user_id = m.member_id
                          and u.member_state = 'approved'
                          and u.authority_id <> :authority_id
                          and acs_permission.permission_p(amo.object_id, u.user_id, 'admin') = 't'
                        )
                    }]
                    aa_equals "Proc should return $expected for authority $authority_id" \
                        $expected [auth::can_admin_system_without_authority_p \
                                       -authority_id $authority_id]
                }

                # Now revoke SWA permissions to everybody and create a
                # single SWA in the test authority. The expected
                # result is that the proc should return true for any
                # authority except the test one, as it is the only one
                # with an admin.
                aa_log "Revoking all SWA privileges"
                foreach user_id [db_list get_swas {
                    select u.user_id
                    from acs_permissions p,
                    party_approved_member_map m,
                    acs_magic_objects amo,
                    cc_users u
                    where amo.name = 'security_context_root'
                    and p.object_id = amo.object_id
                    and p.grantee_id = m.party_id
                    and u.user_id = m.member_id
                    and u.member_state = 'approved'
                    and acs_permission.permission_p(amo.object_id, u.user_id, 'admin') = 't'
                }] {
                    permission::revoke \
                        -party_id $user_id \
                        -object_id [acs_magic_object security_context_root] \
                        -privilege "admin"
                }

                foreach authority_id $authorities {
                    aa_equals "Proc should return 0 for authority $authority_id, as no admins are left" \
                        0 [auth::can_admin_system_without_authority_p \
                               -authority_id $authority_id]
                }

                aa_log "Creating a new SWA in the test authority"
                set test_authority_id [auth::authority::get_id -short_name "acs_testing"]
                set result [acs::test::user::create]
                set user_id [dict get $result user_id]
                permission::grant \
                    -party_id $user_id \
                    -object_id [acs_magic_object security_context_root] \
                    -privilege "admin"

                foreach authority_id $authorities {
                    set expected [expr {$authority_id != $test_authority_id}]
                    aa_equals "Proc should return $expected for authority $authority_id" \
                        $expected \
                        [auth::can_admin_system_without_authority_p \
                             -authority_id $authority_id]
                }

            }
    }

aa_register_case \
    -cats {api} \
    -procs {
        auth::delete_local_account
        acs_user::registered_user_p
        auth::get_local_account_status
    } \
    auth__delete_local_account  {
        Test mainly auth::delete_local_account and
        auth::get_local_account_status
    } {
        aa_run_with_teardown \
            -rollback \
            -test_code {
                set authority_id [auth::authority::get_id -short_name "acs_testing"]
                set result [acs::test::user::create]
                set user_id [dict get $result user_id]
                set username [dict get $result username]

                set account_status [auth::get_local_account_status -user_id $user_id]
                aa_equals "User '$username' should have local status 'ok'" ok $account_status

                set registered_p [acs_user::registered_user_p -user_id $user_id]
                aa_true "User '$username' is currently approved" $registered_p

                aa_log "Calling auth::delete_local_account on the user"
                set r [auth::delete_local_account \
                           -authority_id $authority_id \
                           -username $username]

                set registered_p [acs_user::registered_user_p -user_id $user_id]
                aa_false "User '$username' is not approved anymore" $registered_p
                aa_true "User '$username' still exists" [db_0or1row get_user {
                    select 1 from users where user_id = :user_id
                }]
                set account_status [auth::get_local_account_status -user_id $user_id]
                aa_equals "User '$username' should have local status 'closed'" closed $account_status

                set not_a_user [acs_magic_object security_context_root]
                set account_status [auth::get_local_account_status -user_id $not_a_user]
                aa_equals "Object '$not_a_user' is not an account" no_account $account_status

                aa_true "Proc returns 'delete_status'" [dict exists $r delete_status]
                aa_true "Proc returns 'delete_message'" [dict exists $r delete_status]
            }
    }

aa_register_case \
    -cats {api} \
    -procs {
        auth::get_all_registration_elements
    } \
    auth__get_all_registration_elements {
        Test auth::get_all_registration_elements
    } {
        aa_equals "Proc returns the expected result with flag 'include_password_confirm' set" \
            [lsort [auth::get_all_registration_elements -include_password_confirm]] [lsort {
                email username first_names last_name password
                password_confirm screen_name url
                secret_question secret_answer
            }]
        aa_equals "Proc returns the expected result with flag 'include_password_confirm' NOT set" \
            [lsort [auth::get_all_registration_elements]] [lsort {
                email username first_names last_name password
                screen_name url secret_question secret_answer
            }]
    }

aa_register_case \
    -cats {api} \
    -procs {
        auth::get_register_authority
    } \
    auth__get_register_authority {
        Test auth::get_register_authority
    } {
        aa_run_with_teardown \
            -rollback \
            -test_code {
                set register_authority [auth::get_register_authority]

                # Set all authorities as the register authority one by
                # one and see that the proc returns the expected
                # value.
                db_foreach get_authorities {
                    select authority_id,
                           short_name,
                           register_impl_id
                    from auth_authorities
                } {
                    aa_log "Setting '$short_name' as the registration authority"
                    parameter::set_from_package_key \
                        -parameter RegisterAuthority \
                        -package_key "acs-authentication" \
                        -value $short_name
                    if { $register_impl_id eq "" } {
                        aa_log "Authority '$short_name' does not have a register implementation, fallback to local authority"
                        set reg_authority_id [auth::authority::local]
                    } else {
                        aa_log "Authority '$short_name' has a register implementation"
                        set reg_authority_id $authority_id
                    }
                    aa_equals "Register authority '$short_name' should be picked correctly" \
                        $reg_authority_id [auth::get_register_authority]

                }

                # Finally, try a bogus one.
                set not_exists [db_string get_bogus_authority {
                    select '0' || min(short_name) from auth_authorities
                }]
                parameter::set_from_package_key \
                    -parameter RegisterAuthority \
                    -package_key "acs-authentication" \
                    -value $not_exists
                aa_silence_log_entries -severities error {
                    aa_equals "Non existent register authority '$not_exists' falls back to the local authority" \
                        [auth::authority::local] [auth::get_register_authority]
                }

                #
                # Put the authority back as it was to not pollute
                # the cache.
                #
                parameter::set_from_package_key \
                    -parameter RegisterAuthority \
                    -package_key "acs-authentication" \
                    -value $register_authority
            }
    }

aa_register_case \
    -cats {api} \
    -procs {
        auth::get_user_id
    } \
    auth__get_user_id {
        Test auth::get_user_id
    } {
        # We will just mess about with the ad_conn variables used
        # inside the proc to simulate a few possible situations.
        set prev_untrusted_user_id [ad_conn untrusted_user_id]
        set prev_account_status [ad_conn account_status]
        set prev_auth_level [ad_conn auth_level]

        set user_id [ad_conn user_id]

        set bogus_user [db_string get_bogus_user {
            select max(user_id) + 1 from users
        }]

        aa_run_with_teardown \
            -rollback \
            -test_code {
                foreach {
                    untrusted_user_id account_status auth_level
                    wanted_level wanted_account_status
                    expected_result
                } [list \
                       0           whatever none   1234 whatever 0 \
                       $user_id    ok       ok     ok     ok       $user_id \
                       $user_id    ok       ok     secure ok       [expr {[security::https_available_p] ? 0 : $user_id}] \
                       $user_id    ok       secure secure ok       $user_id \
                       $user_id    ok       secure secure whatever $user_id \
                       $bogus_user ok       secure secure ok       $bogus_user \
                       $bogus_user ko       secure secure ok       0 \
                      ] {
                    ad_conn -set untrusted_user_id $untrusted_user_id
                    ad_conn -set account_status $account_status
                    ad_conn -set auth_level $auth_level

                    set v [auth::get_user_id \
                               -level $wanted_level \
                               -account_status $wanted_account_status]
                    aa_equals "For user '$untrusted_user_id', level '$wanted_level', account_status '$wanted_account_status' the result should be '$expected_result'" \
                        $v $expected_result
                }
            } -teardown_code {
                ad_conn -set untrusted_user_id $prev_untrusted_user_id
                ad_conn -set account_status $prev_account_status
                ad_conn -set auth_level $prev_auth_level
            }
    }

aa_register_case \
    -cats {api} \
    -procs {
        auth::login_attempts::get_all
        auth::login_attempts::reset
        auth::login_attempts::reset_all
        auth::login_attempts::record
        auth::login_attempts::threshold_reached_p
        auth::login_attempts::get
    } \
    auth__login_attempts {
        Test login attempts API
    } {
        set orig_max_failed_login_attempts [parameter::get_from_package_key \
                                                -parameter "MaxConsecutiveFailedLoginAttempts" \
                                                -package_key "acs-authentication" \
                                                -default 0]
        try {
            # We set this value forcefully or chances are that
            # some system will never test this API
            set max_failed_login_attempts 10
            parameter::set_from_package_key \
                -parameter "MaxConsecutiveFailedLoginAttempts" \
                -package_key "acs-authentication" \
                -value $max_failed_login_attempts

            set login_attempt_key acs-test-login-key
            set another_login_attempt_key acs-test-login-another-key

            for {set i 1} {$i <= $max_failed_login_attempts} {incr i} {
                ::auth::login_attempts::record \
                    -login_attempt_key $login_attempt_key
                aa_equals "Login attempts for key '$login_attempt_key' should now be '$i'" \
                    $i [::auth::login_attempts::get -key $login_attempt_key]
                aa_false "Threshold for key '$login_attempt_key' should not have been reached" \
                    [::auth::login_attempts::threshold_reached_p \
                         -login_attempt_key $login_attempt_key]
            }

            ::auth::login_attempts::record \
                -login_attempt_key $login_attempt_key
            aa_true "Threshold for key '$login_attempt_key' should now have been reached" \
                [::auth::login_attempts::threshold_reached_p \
                     -login_attempt_key $login_attempt_key]

            aa_log "Forgetting of login attempts for '$another_login_attempt_key'"
            auth::login_attempts::reset \
                -login_attempt_key $another_login_attempt_key

            aa_true "Threshold for key '$login_attempt_key' should still have been reached" \
                [::auth::login_attempts::threshold_reached_p \
                     -login_attempt_key $login_attempt_key]

            aa_log "Forgetting of login attempts for '$login_attempt_key'"
            auth::login_attempts::reset \
                -login_attempt_key $login_attempt_key

            aa_false "Threshold for key '$login_attempt_key' should now be fine" \
                [::auth::login_attempts::threshold_reached_p \
                     -login_attempt_key $login_attempt_key]
            aa_equals "Number of attempts for key '$login_attempt_key' should now be 0" \
                0 [::auth::login_attempts::get \
                       -key $login_attempt_key]

            aa_log "Resetting all attempts"
            auth::login_attempts::reset_all
            aa_true "No attempts anymore..." \
                {[llength [auth::login_attempts::get_all]] == 0}

            aa_log "Record two attempts on different keys"

            ::auth::login_attempts::record \
                -login_attempt_key $login_attempt_key
            aa_equals "Number of attempts for key '$login_attempt_key' should now be 1" \
                1 [::auth::login_attempts::get \
                       -key $login_attempt_key]

            ::auth::login_attempts::record \
                -login_attempt_key $another_login_attempt_key
            aa_equals "Number of attempts for key '$another_login_attempt_key' should now be 1" \
                1 [::auth::login_attempts::get \
                       -key $another_login_attempt_key]

            set all_attempts [auth::login_attempts::get_all]

            set keys_to_expect [list \
                                    $login_attempt_key \
                                    $another_login_attempt_key]
            aa_equals "auth::login_attempts::get_all returns the expected number of entries" \
                [llength $all_attempts] [expr {3 * 2}]
            foreach {key timeout number_of_attempts} $all_attempts {
                aa_true "auth::login_attempts::get_all returns an integer for timeout" \
                    [string is integer -strict $timeout]
                aa_equals "auth::login_attempts::get_all returns the correct number of attempts" \
                    1 $number_of_attempts
                set i [lsearch -exact $keys_to_expect $key]
                aa_true "auth::login_attempts::get_all the correct keys" \
                    {$i >= 0}
                set keys_to_expect [lreplace $keys_to_expect $i $i]
            }

            aa_log "Resetting all attempts"
            auth::login_attempts::reset_all

            aa_true "No attempts anymore..." \
                {[llength [auth::login_attempts::get_all]] == 0}
        } finally {
            parameter::set_from_package_key \
                -parameter "MaxConsecutiveFailedLoginAttempts" \
                -package_key "acs-authentication" \
                -value $orig_max_failed_login_attempts
        }
    }

aa_register_case \
    -cats {api} \
    -procs {
        auth::refresh_login
    } \
    auth__refresh_login {
        Test auth::refresh_login
    } {
        try {
            set endpoint_name test__auth__refresh_login
            ns_register_proc GET $endpoint_name {
                set auth_level [ns_queryget auth_level]
                if {$auth_level ne ""} {
                    ad_conn -set auth_level $auth_level
                }
                ad_unless_script_abort {
                    set user_id [auth::refresh_login]
                } {
                    ns_return 200 text/plain $user_id
                }
            }

            set result [acs::test::user::create]
            set user_id [dict get $result user_id]

            set d [acs::test::http -user_id $user_id \
                       -method GET /$endpoint_name]
            acs::test::reply_has_status_code $d 200
            aa_equals "Response must be the supplied user_id '$user_id'" \
                [dict get $d body] $user_id

            set d [acs::test::http -user_id $user_id \
                       -method GET /$endpoint_name?auth_level=expired]
            acs::test::reply_has_status_code $d 302

        } finally {
            ns_unregister_op GET $endpoint_name
            acs_user::delete -user_id $user_id -permanent
        }
    }

aa_register_case \
    -cats {api} \
    -procs {
        auth::self_registration
    } \
    auth__self_registration {
        Test auth::self_registration
    } {
        set old_allow_self_register_p [parameter::get_from_package_key \
                                           -package_key acs-authentication \
                                           -parameter AllowSelfRegister]
        try {
            set endpoint_name test__auth__self_registration
            ns_register_proc GET $endpoint_name {
                ad_unless_script_abort {
                    set user_id [auth::self_registration]
                } {
                    ns_return 200 text/plain $user_id
                }
            }

            set result [acs::test::user::create]
            set user_id [dict get $result user_id]

            aa_section "Set AllowSelfRegister to false"
            parameter::set_from_package_key \
                -package_key acs-authentication \
                -parameter AllowSelfRegister \
                -value false

            aa_log "Unauthenticated request"
            set d [acs::test::http \
                       -method GET /$endpoint_name]
            acs::test::reply_has_status_code $d 302

            aa_log "Authenticated request"
            set d [acs::test::http -user_id $user_id \
                       -method GET /$endpoint_name]
            acs::test::reply_has_status_code $d 200
            aa_equals "Response must be the supplied user_id '$user_id'" \
                [dict get $d body] $user_id

            aa_section "Set AllowSelfRegister to true"
            parameter::set_from_package_key \
                -package_key acs-authentication \
                -parameter AllowSelfRegister \
                -value true

            aa_log "Unauthenticated request"
            set d [acs::test::http \
                       -method GET /$endpoint_name]
            acs::test::reply_has_status_code $d 200
            aa_equals "Response must be empty" \
                [dict get $d body] ""

            aa_log "Authenticated request"
            set d [acs::test::http -user_id $user_id \
                       -method GET /$endpoint_name]
            acs::test::reply_has_status_code $d 200
            aa_equals "Response must be empty" \
                [dict get $d body] ""

        } finally {
            parameter::set_from_package_key \
                -package_key acs-authentication \
                -parameter AllowSelfRegister \
                -value $old_allow_self_register_p
            ns_unregister_op GET $endpoint_name
            acs_user::delete -user_id $user_id -permanent
        }
    }

aa_register_case \
    -cats {api} \
    -procs {
        auth::update_local_account
    } \
    auth__update_local_account {
        Test auth::update_local_account
    } {
        aa_run_with_teardown \
            -rollback \
            -test_code {
                set result [acs::test::user::create]
                set user_id [dict get $result user_id]

                set u [acs_user::get -user_id $user_id]
                set authority_id [dict get $u authority_id]
                set test_authority_id $authority_id
                set username [dict get $u username]

                set other_authority_id [db_string get_authority {
                    select min(authority_id) from auth_authorities
                    where authority_id <> :test_authority_id
                }]

                foreach update_infos [list \
                                          [list [list \
                                                     email_verified_p f \
                                                     screen_name abcd \
                                                     authority_id $other_authority_id \
                                                     bio "a bio" \
                                                     first_names Jonh \
                                                     last_name Doe \
                                                     username anotheruser \
                                                     email valid@email.com \
                                                     url http://avalidurl.com \
                                                     whatever blabla] true]\
                                          [list [list \
                                                     email_verified_p t \
                                                     screen_name abcde \
                                                     authority_id $test_authority_id \
                                                     bio "another bio" \
                                                     first_names Jonh2 \
                                                     last_name Doe2 \
                                                     username anotheruser2 \
                                                     email invalidemail.com \
                                                     url http://avalidurl.com \
                                                     whatever blabla] false] \
                                          [list [list \
                                                     first_names Jonh3 \
                                                     last_name Doe3] true]] {
                    lassign $update_infos data correct_p

                    set not [expr {$correct_p ? "" : "not "}]
                    aa_section "Updating user '$user_id' with $data, supposed to be ${not}correct"

                    unset -nocomplain update_data
                    array set update_data $data

                    set result [auth::update_local_account \
                                    -authority_id $authority_id \
                                    -username $username \
                                    -array update_data]

                    # Update the info we supply to the proc when the
                    # update should succeed.
                    if {$correct_p} {
                        if {[dict exists $data authority_id]} {
                            set authority_id [dict get $data authority_id]
                        }
                        if {[dict exists $data username]} {
                            set username [dict get $data username]
                        }
                    }

                    set expected_keys [lsort -unique \
                                           [list {*}[dict keys $result] \
                                                update_status update_message element_messages]]
                    aa_equals "Proc returns the expected entries" \
                        [lsort [dict keys $result]] \
                        $expected_keys

                    set expected_status [expr {$correct_p ? "ok" : "data_error"}]
                    aa_equals "Update status is '$expected_status' -> $result" \
                        [dict get $result update_status] \
                        $expected_status

                    if {$correct_p} {
                        set updated_user [acs_user::get -user_id $user_id]
                        foreach {key expected_value} $data {
                            if {[dict exists $updated_user $key]} {
                                aa_equals "Attribute '$key' was updated to '$expected_value'" \
                                    [dict get $updated_user $key] $expected_value
                            }
                        }
                    }
                }
            }
    }

aa_register_case \
    -cats {api} \
    -procs {
        auth::verify_account_status
    } \
    auth__verify_account_status {
        Test auth::verify_account_status
    } {
        try {
            set endpoint_name test__auth__verify_account_status
            ns_register_proc GET $endpoint_name {
                ad_conn -set auth_level somenonsense
                auth::verify_account_status
                ns_return 200 text/plain [ad_conn auth_level]
            }

            set user_info [acs::test::user::create -admin]
            set user_id [dict get $user_info user_id]
            acs::test::confirm_email -user_id $user_id
            set d [::acs::test::login $user_info]

            set expected_statuses {ok secure}

            aa_section "Accessing the test endpoint as user '$user_id'"
            set d [acs::test::http \
                       -last_request $d \
                       -method GET /$endpoint_name]
            acs::test::reply_has_status_code $d 200

            set auth_level [dict get $d body]
            aa_true "Returned '$auth_level' is among the expected ones '$expected_statuses'" \
                {$auth_level in $expected_statuses}

            aa_section "Accessing the test endpoint as nobody"
            set d [acs::test::http \
                       -method GET /$endpoint_name]
            acs::test::reply_has_status_code $d 200
            aa_equals "Returned auth_level is 'none'" \
                [dict get $d body] "none"

        } finally {
            ns_unregister_op GET $endpoint_name
            acs_user::delete -user_id $user_id -permanent
        }
    }

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
