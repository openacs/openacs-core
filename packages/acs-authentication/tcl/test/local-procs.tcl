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
