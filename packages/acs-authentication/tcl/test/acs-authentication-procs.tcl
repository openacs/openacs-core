ad_library {
  Register acs-automated-testing test cases for the workflow
  package on server startup.

  @author Peter Marklund
  @creation-date 21 August 2003
  @cvs-id $Id$
}

aa_register_case auth_authenticate {
    Test the auth::authenticate proc.

    @author Peter Marklund
} {    
    aa_run_with_teardown \
        -test_code {

            # Initialize variables
            set user_id [ad_conn user_id]
            db_1row get_admin_info {
                select email,
                       password as original_password,
                       member_state as original_member_state
                from cc_users
                where user_id = :user_id
            }      
            # We need to use a known password and the existing one cannot
            # be retrieved
            set password "test_password"
            ad_change_password $user_id $password

            # Successful authentication
            array set auth_info \
                [auth::authenticate \
                     -username $email \
                     -password $password]
    
            aa_equals "auth_status for successful authentication" $auth_info(auth_status) "ok"

            # Failed authentications
            # Incorrect password
            array set auth_info \
                [auth::authenticate \
                     -username $email \
                     -password "blabla"]

            aa_equals "auth_status for bad password authentication" $auth_info(auth_status) "bad_password"
            aa_true "auth_message for bad password authentication" ![empty_string_p $auth_info(auth_message)]

            # Blank password
            array set auth_info \
                [auth::authenticate \
                     -username $email \
                     -password ""]

            aa_equals "auth_status for blank password authentication" $auth_info(auth_status) "bad_password"
            aa_true "auth_message for blank password authentication" ![empty_string_p $auth_info(auth_message)]

            # Incorrect username
            array set auth_info \
                [auth::authenticate \
                     -username "blabla" \
                     -password $password]

            aa_equals "auth_status for bad username authentication" $auth_info(auth_status) "no_account"
            aa_true "auth_message for bad username authentication" ![empty_string_p $auth_info(auth_message)]

            # Blank username
            array set auth_info \
                [auth::authenticate \
                     -username "" \
                     -password $password]

            aa_equals "auth_status for blank username authentication" $auth_info(auth_status) "no_account"
            aa_true "auth_message for blank username authentication" ![empty_string_p $auth_info(auth_message)]

            # Authority bogus
            array set auth_info \
                [auth::authenticate \
                     -authority_id -123 \
                     -username $email \
                     -password $password]

            aa_equals "auth_status for bad authority_id authentication" $auth_info(auth_status) "auth_error"
            aa_true "auth_message for bad authority_id authentication" ![empty_string_p $auth_info(auth_message)]

            # Closed account status
            set closed_states {banned rejected "needs approval" deleted}
            foreach closed_state $closed_states {
                acs_user::change_state -user_id $user_id -state $closed_state

                # Successful authentication
                array set auth_info \
                    [auth::authenticate \
                         -username $email \
                         -password $password]
    
                aa_equals "auth_status for successful authentication" $auth_info(auth_status) "ok"        
                aa_equals "account_status for successful authentication" $auth_info(account_status) "closed"
            }
    
            # Error handling    

        } -teardown_code {

            # Reset password and member state
            db_dml update_password {
                update users
                set password = :original_password
                where user_id = :user_id
            }
            acs_user::change_state -user_id $user_id -state $original_member_state
        }
}

aa_register_case auth_create_user {
    Test the auth::create_user proc.

    @author Peter Marklund
} {
    db_transaction {

        # Successful creation
         array set user_info [auth::create_user \
                                  -username "auth_create_user1@test_user.com" \
                                  -first_names "Test" \
                                  -last_name "User" \
                                  -password "changeme" \
                                  -secret_question "no_question" \
                                  -secret_answer "no_answer"]
         set successful_result(user_id) $user_info(user_id)
         set successful_result(creation_status) $user_info(creation_status)
         set successful_result(creation_message) $user_info(creation_message)

         # Missing first_names
         array set user_info [auth::create_user \
                                  -username "auth_create_user2@test_user.com" \
                                  -first_names "" \
                                  -last_name "User" \
                                  -password "changeme" \
                                  -secret_question "no_question" \
                                  -secret_answer "no_answer"]

         set first_names_result(creation_status) $user_info(creation_status)
         
         error "rollback tests"

    } on_error {
        if { ![string equal $errmsg "rollback tests"] } {
            global errorInfo
            
            error "Tests threw error $errmsg \n\n $errorInfo"
        }
    }

    aa_true "returns integer user_id ([array get user_info])" [regexp {[1-9][0-9]*} $successful_result(user_id)]
    aa_equals "creation_status for successful creation" $successful_result(creation_status) "ok"
    aa_true "creation_message for successful creation" [empty_string_p $successful_result(creation_message)]

    aa_equals "creation_status for missing first names" $first_names_result(creation_status) "fail"
}

aa_register_case auth_confirm_email {
    Test the auth::confirm_email proc.

    @author Peter Marklund
} {
    set user_id [ad_conn user_id]

    auth::confirm_email -user_id $user_id

    # Check that update was made in db
    set email_verified_p [db_string select_email_verified_p {
        select email_verified_p
        from cc_users
        where user_id = :user_id
    }]

    aa_equals "email should be verified" $email_verified_p "t"
}

aa_register_case auth_get_registration_elements {
    Test the auth::get_registration_elements proc

    @author Peter Marklund
} {
    array set element_array [auth::get_registration_elements]

    aa_true "there is more than one required element: ($element_array(required))" [expr [llength $element_array(required)] > 0]
    aa_true "there is more than one optional element: ($element_array(optional))" [expr [llength $element_array(optional)] > 0]
}

aa_register_case auth_get_registration_form_elements {
    Test the auth::get_registration_form_elements proc

    @auth Peter Marklund
} {
    set form_elements [auth::get_registration_form_elements]

    aa_true "Form elements are not empty: $form_elements" [expr ![empty_string_p $form_elements]]
}

aa_register_case auth_password_get_change_url {
    Test the auth::password::get_change_url proc.

    @author Simon Carstensen
} {

    # Test whether auth::password::get_change_url returns and empty string when "change_pwd_url" is not se

    db_0or1row get_user_id { 
        select o.creation_user,
               change_pwd_url as expected_result
        from   acs_objects o,
               auth_authorities a
        where  a.authority_id = o.object_id
        and    a.change_pwd_url != null
        limit  1
    } -default ""]

    aa_equals "Check that auth::password::get_change_url returns correct redirect URL when change_pwd_url is not null" \
        [auth::password::get_change_url -user_id $user_id ] \
        $expected_result

    # Test whether auth::password::get_change_url returns the correct URL to redirect when "change_pwd_url" is set. 
    set user_id [db_string get_user_id { 
        select o.creation_user
        from   acs_objects o,
               auth_authorities a
        where  a.authority_id = o.object_id
        and    a.change_pwd_url = null
        limit  1
    } -default ""]

    set expected_result ""

    aa_equals "Check that auth::password::get_change_url returns empty string when change_pwd_url is null. " \
        [auth::password::get_change_url -user_id $user_id] \
        $expected_result
}

aa_register_case auth_password_can_change_p {
    Test the auth::password::can_change_p proc.

    @author Simon Carstensen
} {
    
    set user_id [db_string get_user_id { 
        select o.creation_user
        from   acs_objects o,
               auth_authorities a
        where  a.authority_id = o.object_id
        and    a.short_name = 'local'
        limit  1
    } -default ""]

    aa_equals "Should return 1 when CanChangePassword is true for the local driver " \
        [auth::password::can_change_url -user_id $user_id] \
        "1"
}

aa_register_case auth_password_change {
    Test the auth::password::change proc.

    @author Simon Carstensen
} {
    # create user we'll use for testing
    set user_id [ad_user_new "test@user.com" "Test" "User" "changeme" "no_question" "no_answer"]

    # password_status "ok"
    set old_password "changeme"
    set new_password "changedyou"
    array set auth_info [auth::password::change -user_id $user_id -old_password $old_password -new_password $new_password]
    aa_equals "Should return 'ok'" \
        $auth_info(password_status) \
        "ok"

    # check that the new password is actually set correctly
    set password_correct_p [ad_check_password $user_id $new_password]
    aa_equals "check that the new password is actually set correctly" \
        $password_correct_p \
        "1"

    # Teardown user

    # password should not be changed if password is an empty string
#     set old_password "changedyou"
#     set new_password ""
#     array set auth_info [auth::password::change -user_id $user_id -old_password $old_password -new_password $new_password]
#     aa_equals "Should return 'ok'" \
#         $auth_info(password_status) \
#         "ok"

}

aa_register_case auth_password_forgotten {
    Test the auth::password::forgotten proc.

    @author Simon Carstensen
} {
    # Test password_status on local driver for ok
}

aa_register_case auth_password_get_forgotten_url {
    Test the auth::password::get_forgotten_url proc.

    @author Simon Carstensen
} {
    # Call auth::password::get_forgotten_url with the -remote_only switch and test whether it returns an empty string when username and authority is not specified, if not that it returns the authority's forgotten_pwd_url if non-empty (with [ns_urlencode username] correctly interpolated into the URL), else that it returns empty string.
    # Call auth::password::get_forgotten_url without the -remote_only switch and test that it returns authority's forgotten_pwd_url if non-empty, that if authority's pwd mgr returns 1 for either CanRetrieve or CanReset it returns /register/forgotten-password?[export_vars { authority_id username }] 
}

aa_register_case auth_password_retrieve {
    Test the auth::password::retrieve proc.

    @author Simon Carstensen
} {
    # Test password_status for ok
    # Test whether password is correct 
}

aa_register_case auth_password_reset {
    Test the auth::password::reset proc.

    @author Simon Carstensen
} {
    # Test password_status for ok
    # Test whether password actually changed
}

#####
#
# Helper procs
#
####

namespace eval auth::test {}

ad_proc -private auth::test::get_admin_user_id {} {
    Return the user id of a site-wide-admin on the system
} {
    set context_root_id [acs_lookup_magic_object security_context_root]

    return [db_string select_user_id {}]
}
