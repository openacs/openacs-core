ad_library {
    Automated tests.

    @author Peter Marklund
    @creation-date 20 April 2004
    @cvs-id $Id$
}

aa_register_case -cats {web smoke} -libraries tclwebtest tclwebtest_example {
    A simple test case demonstrating the use of tclwebtest (HTTP level testing).

    @author Peter Marklund
} {
    set user_id [db_nextval acs_object_id_seq]

    aa_run_with_teardown \
        -test_code {
            # Create test user
            array set user_info [twt::user::create -user_id $user_id]

            # Login user
            twt::user::login $user_info(email) $user_info(password)

            # Visit homepage
            twt::do_request "/"

	    # Logout user
            twt::user::logout

        } -teardown_code {
            # TODO: delete test user
            twt::user::delete -user_id $user_id
        }
}
