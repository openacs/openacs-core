ad_library {
    Automated tests.

    @author Peter Marklund
    @creation-date 26 July 2018
}

aa_register_case \
    -cats {api web} \
    -procs {
        acs::test::user::create
        acs::test::user::login
        acs::test::user::logout
    } \
    webtest_example {

    A simple test case demonstrating the use of web tests (via
    HTTP/HTTPS).

    @author Gustaf Neumann
} {

    aa_run_with_teardown -test_code {
        set user_id [db_nextval acs_object_id_seq]

        # Create test user
        set user_info [acs::test::user::create -user_id $user_id]

        # Login user
        set d [acs::test::login $user_info]

        # Visit homepage, last name of user should be contained
        set d [acs::test::http -session $d /]

        acs::test::reply_has_status_code $d 200
        acs::test::reply_contains $d [dict get $user_info last_name]

        # Logout user
        set d [acs::test::logout -session $d]

        # Visit homepage, last name of user should not show up
        set d [acs::test::http -session $d /]
        acs::test::reply_contains_no $d [dict get $user_info last_name]

    } -teardown_code {
        acs::test::user::delete -user_id $user_id
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
