ad_library {
    Automated tests.

    @author Peter Marklund
    @creation-date 26 July 2018
}

aa_register_case \
    -cats {api web} \
    -procs {
        acs::test::user::create
        acs::test::http
        acs::test::login
        acs::test::logout
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

        ########################################################################################
        aa_section "Visit homepage as anonymous user, last name of user should not show up"
        ########################################################################################
        set d [acs::test::http /]
        acs::test::reply_contains_no $d [dict get $user_info last_name]

        # Login user
        #set d [acs::test::login $user_info]

        ########################################################################################
        aa_section "Visit homepage with user_info, should login, last name of user should be contained"
        ########################################################################################
        set d [acs::test::http -user_info $user_info -session $d /]

        acs::test::reply_has_status_code $d 200
        acs::test::reply_contains $d [dict get $user_info last_name]
        aa_equals "login [dict get $d login]" [dict get $d login] via_login
        aa_true "cookies are not empty '[dict get $d cookies]'" {[dict get $d cookies] ne ""}

        ########################################################################################
        aa_section "Make a second request, now the cookie should be used"
        ########################################################################################
        set d [acs::test::http -user_info $user_info -session $d /]
        acs::test::reply_has_status_code $d 200
        acs::test::reply_contains $d [dict get $user_info last_name]
        aa_equals "login [dict get $d login]" [dict get $d login] via_cookie

        ########################################################################################
        aa_section "Logout user"
        ########################################################################################
        set d [acs::test::logout -session $d]

        ########################################################################################
        aa_section "Visit homepage, last name of user should not show up"
        ########################################################################################
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
