ad_library {

    Tests for procs in tcl/local-procs.tcl

}

aa_register_case \
    -cats {api smoke} \
    -procs {
        auth::local::authentication::MergeUser
        membership_rel::change_state
        acs_user::get
        acs_user::update
        party::update
    } \
    auth_authentication_implementations {
        Test implementations of the auth_authentication contract
    } {
        aa_run_with_teardown -rollback -test_code {
            set user1 [acs::test::user::create]
            set user2 [acs::test::user::create]

            set user_id1 [dict get $user1 user_id]
            set username1 [dict get $user1 username]
            set email1 [dict get $user1 email]

            set user_id2 [dict get $user2 user_id]
            set username2 [dict get $user2 username]
            set email2 [dict get $user2 email]

            acs_sc::invoke \
                -contract auth_authentication \
                -operation MergeUser \
                -impl local \
                -call_args [list $user_id1 $user_id2 ""]

            set user1_after [acs_user::get -user_id $user_id1]

            aa_equals "Username for user '$user_id1' is as expected" \
                [dict get $user1_after username] merged_${user_id1}_${user_id2}
            aa_equals "Email for user '$user_id1' is as expected" \
                [dict get $user1_after email] merged_${user_id1}_${user_id2}
            aa_equals "Screen name for user '$user_id1' is as expected" \
                [dict get $user1_after screen_name] merged_${user_id1}_${user_id2}
            aa_equals "Member state for user '$user_id1' is as expected" \
                [dict get $user1_after member_state] merged
        }
    }

aa_register_case \
    -cats {api smoke} \
    -procs {
        auth::local::password::CanChangePassword
        auth::local::password::CanResetPassword
        auth::local::password::CanRetrievePassword
        auth::local::password::GetParameters
        auth::local::password::ChangePassword
        auth::local::password::ResetPassword
        auth::local::password::RetrievePassword
        ad_check_password
    } \
    auth_password_implementations {
        Test implementations of the auth_password contract
    } {
        aa_stub acs_mail_lite::send {
            set ::auth_password_implementations_to_addr $to_addr
            set ::auth_password_implementations_body $body
        }

        aa_true "CanChangePassword is always true" [acs_sc::invoke \
                                                        -contract auth_password \
                                                        -operation CanChangePassword \
                                                        -impl local \
                                                        -call_args [list ""]]
        aa_true "CanResetPassword is always true" [acs_sc::invoke \
                                                       -contract auth_password \
                                                       -operation CanResetPassword \
                                                       -impl local \
                                                       -call_args [list ""]]
        aa_true "CanRetrievePassword is always true" [acs_sc::invoke \
                                                          -contract auth_password \
                                                          -operation CanRetrievePassword \
                                                          -impl local \
                                                          -call_args [list ""]]

        aa_equals "GetParameters returns nothing" \
            [acs_sc::invoke \
                 -contract auth_password \
                 -operation GetParameters \
                 -impl local] \
            ""

        aa_run_with_teardown -rollback -test_code {
            set user [acs::test::user::create]
            set user_id [dict get $user user_id]
            set old_password [dict get $user password]
            set user [acs_user::get -user_id $user_id]

            set username [dict get $user username]
            set authority_id [dict get $user authority_id]

            aa_section "Changing password"
            set new_password 1234
            acs_sc::invoke \
                -contract auth_password \
                -operation ChangePassword \
                -impl local \
                -call_args [list \
                                $username \
                                $new_password \
                                $old_password \
                                [list] \
                                $authority_id]
            aa_true "Password was changed" [ad_check_password $user_id $new_password]

            aa_section "Resetting password"
            set result [acs_sc::invoke \
                            -contract auth_password \
                            -operation ResetPassword \
                            -impl local \
                            -call_args [list \
                                            $username \
                                            [list] \
                                            $authority_id]]
            set new_password [dict get $result password]
            aa_true "Password was reset" [ad_check_password $user_id $new_password]

            aa_section "Retrieving password"
            acs_sc::invoke \
                -contract auth_password \
                -operation RetrievePassword \
                -impl local \
                -call_args [list $username [list]]
            set email [dict get $user email]
            set password [dict get $user password]
            aa_equals "Email was sent to the user" \
                [dict get $user email] $::auth_password_implementations_to_addr
            set password [db_string query {
                select password from users where user_id = :user_id
            }]
            aa_true "Email contains a link to the password hash" \
                {[string first \
                      [ns_urlencode $password] \
                      $::auth_password_implementations_body] >= 0}
        }
    }
