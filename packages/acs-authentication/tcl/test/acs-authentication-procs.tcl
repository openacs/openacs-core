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
    # Initialize variables
    set user_id [ad_conn user_id]
    db_1row get_admin_info {
        select email
        from cc_users
        where user_id = :user_id
    }      
    # We need to use a known password and the existing one cannot
    # be retrieved
    set password "test_password"

    aa_run_with_teardown \
        -rollback \
        -test_code {

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
            # TODO or too hard?
        }
}

aa_register_case auth_create_user {
    Test the auth::create_user proc.

    @author Peter Marklund
} {

    aa_run_with_teardown \
        -rollback \
        -test_code {

        # Successful creation
         array set user_info [auth::create_user \
                                  -username "auth_create_user1@test_user.com" \
                                  -first_names "Test" \
                                  -last_name "User" \
                                  -password "changeme" \
                                  -secret_question "no_question" \
                                  -secret_answer "no_answer"]

         aa_true "returns integer user_id ([array get user_info])" [regexp {[1-9][0-9]*} $user_info(user_id)]
         aa_equals "creation_status for successful creation" $user_info(creation_status) "ok"
         aa_true "creation_message for successful creation" [empty_string_p $user_info(creation_message)]

         # Missing first_names
         array set user_info [auth::create_user \
                                  -username "auth_create_user2@test_user.com" \
                                  -first_names "" \
                                  -last_name "User" \
                                  -password "changeme" \
                                  -secret_question "no_question" \
                                  -secret_answer "no_answer"]

         aa_equals "creation_status for missing first names" $user_info(creation_status) "fail"         

    } 
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

###########
#
# Password API
#
###########

aa_register_case auth_password_get_change_url {
    Test the auth::password::get_change_url proc.

    @author Simon Carstensen
} {

    # Test whether auth::password::get_change_url returns the correct URL to redirect when "change_pwd_url" is set. 
    auth::test::get_password_vars -array_name test_vars

    if { [info exists test_vars(user_id)] } {
        set change_pwd_url [auth::password::get_change_url -user_id $test_vars(user_id)]
        aa_true "Check that auth::password::get_change_url returns correct redirect URL when change_pwd_url is not null" \
            [regexp {password-update} $change_pwd_url]            
    }
}

aa_register_case auth_password_can_change_p {
    Test the auth::password::can_change_p proc.

    @author Simon Carstensen
} {
    auth::test::get_password_vars -array_name test_vars
    
    aa_equals "Should return 1 when CanChangePassword is true for the local driver " \
        [auth::password::can_change_p -user_id $test_vars(user_id)] \
        "1"
}

aa_register_case auth_password_change {
    Test the auth::password::change proc.

    @author Simon Carstensen
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {
            # create user we'll use for testing
            set user_id [ad_user_new "test2@user.com" "Test" "User" "changeme" "no_question" "no_answer"]

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
        }
}

aa_register_case auth_password_recovver {
    Test the auth::password::recover_password proc.

    @author Simon Carstensen
} {
    auth::test::get_password_vars -array_name test_vars

    # Stub get_forgotten_url to avoid the redirect
    aa_stub auth::password::get_forgotten_url {
        return ""
    }
    
    # We don't want email to go out
    aa_stub auth::password::email_password {
        return
    }
    
    aa_run_with_teardown \
        -rollback \
        -test_code {
            array set password_result [auth::password::recover_password \
                                           -authority_id $test_vars(authority_id) \
                                           -username $test_vars(username)]

            aa_equals "status ok" $password_result(password_status) "ok"
            aa_true "non-empty message" [expr ![empty_string_p $password_result(password_message)]]
        }
}

aa_register_case auth_password_get_forgotten_url {
    Test the auth::password::get_forgotten_url proc.

    @author Simon Carstensen
} {
    auth::test::get_password_vars -array_name test_vars    

    # With user info
    set url [auth::password::get_forgotten_url -authority_id $test_vars(authority_id) -username $test_vars(username)]
    aa_true "there is a local forgotten-password page with user info" [regexp {recover-password} $url]

    set url [auth::password::get_forgotten_url -authority_id $test_vars(authority_id) -username $test_vars(username) -remote_only]
    aa_equals "cannot get remote url with missing forgotten_pwd_url" $url ""

    # Without user info
    set url [auth::password::get_forgotten_url -authority_id "" -username "" -remote_only]
    aa_equals "cannot get remote url without user info" $url ""

    set url [auth::password::get_forgotten_url -authority_id "" -username ""]
    aa_true "there is a local forgotten-password page without user info" [regexp {forgotten-password} $url]
}

aa_register_case auth_password_retrieve {
    Test the auth::password::retrieve proc.

    @author Simon Carstensen
} {
    auth::test::get_password_vars -array_name test_vars    
    array set result [auth::password::retrieve \
                          -authority_id $test_vars(authority_id) \
                          -username $test_vars(username)]
    
    aa_equals "cannot retrieve pwd from local auth" $result(password_status) "not_supported"
    aa_true "must have message on failure" [expr ![empty_string_p $result(password_message)]]
}

aa_register_case auth_password_reset {
    Test the auth::password::reset proc.

    @author Simon Carstensen
} {
    # We don't want email to go out
    aa_stub auth::password::email_password {
        return
    }

    aa_run_with_teardown \
        -rollback \
        -test_code {
            array set test_user {
                username "test_username"
                password "test_password"
                first_names "test_first_names"
                last_name  "test_last_name"
            }

            array set create_result [auth::create_user \
                                         -username $test_user(username) \
                                         -password $test_user(password) \
                                         -first_names $test_user(first_names) \
                                         -last_name $test_user(last_name)]
            aa_equals "status should be ok for creating user" $create_result(creation_status) "ok"
            
                
            array set reset_result [auth::password::reset \
                                        -authority_id [auth::authority::local] \
                                        -username $test_user(username)] 
            aa_equals "status should be ok for reseting password" $reset_result(password_status) "ok"

            array set auth_result [auth::authentication::Authenticate \
                                     -username $test_user(username) \
                                     -authority_id [auth::authority::local] \
                                     -password $reset_result(password)]
            aa_equals "can authenticate with new password" $auth_result(auth_status) "ok"
            
            array set auth_result [auth::authentication::Authenticate \
                                     -username $test_user(username) \
                                     -authority_id [auth::authority::local] \
                                     -password $test_user(password)]
            aa_false "cannot authenticate with old password" [string equal $auth_result(auth_status) "ok"]
        }
}

###########
#
# Authority Management API
#
###########

aa_register_case auth_authority_api {
    Test the auth::authority::create, auth::authority::edit, and auth::authority::delete procs.

    @author Simon Carstensen
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {

            # Add authority and test that it was added correctly.
            array set columns {
                short_name "test"
                pretty_name "Test authority"
                help_contact_text "Blah blah"
                enabled_p "t"
                sort_order "1000"
                auth_impl_id ""
                pwd_impl_id ""
                forgotten_pwd_url ""
                change_pwd_url ""
                register_impl_id ""
                register_url ""
            }

            
            set authority_id [auth::authority::create -array columns]

            set authority_added_p [db_string authority_added_p {
                select count(*) from auth_authorities where authority_id = :authority_id
            } -default "0"]

            aa_true "was the authority added?" $authority_added_p

            # Edit authority and test that it has actually changed.
            array set columns {
                short_name "test2"
                pretty_name "Test authority2"
                help_contact_text "Blah blah2"
                enabled_p "f"
                sort_order "1001"
                forgotten_pwd_url "foobar.com"
                change_pwd_url "foobar.com"
                register_url "foobar.com"
            }

            auth::authority::edit \
                -authority_id $authority_id \
                -array columns

            auth::authority::get \
                -authority_id $authority_id \
                -array edit_result

            foreach column [array names columns] {
                aa_equals "edited column $column" $edit_result($column) $columns($column)
            }

            # Delete authority and test that it was actually added.
            auth::authority::delete -authority_id $authority_id

            set authority_exists_p [db_string authority_added_p {
                select count(*) from auth_authorities where authority_id = :authority_id
            } -default "0"]

            aa_false "was the authority deleted?" $authority_exists_p
        }
}


aa_register_case auth_driver_get_parameters {
    Test the auth::driver::get_parameters proc.

    @author Simon Carstensen (simon@collaboraid.biz)
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {        
            set impl_id [db_string select_impl_id {
                select auth_impl_id
                from   auth_authorities
                where  short_name = 'local'
            }]
    
            set parameters [auth::driver::get_parameters -impl_id $impl_id]

            aa_true "List of parameters should be empty for local authority" [empty_string_p $parameters]

        }
}

aa_register_case auth_driver_get_parameter_values {
    Test the auth::driver::set_parameter_values proc.

    @author Simon Carstensen (simon@collaboraid.biz)
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {
            db_1row select_vars {
                select auth_impl_id as impl_id,
                       authority_id
                from   auth_authorities
                where  short_name = 'local'
            }

            set key "foo"
            set value "bar"

            db_dml insert_test_parameter {
                insert into auth_driver_params(
                    impl_id, authority_id, key, value
                 ) values (
                    :impl_id, :authority_id, :key, :value
                 )
            }

            set values [auth::driver::get_parameter_values \
                            -impl_id $impl_id \
                            -authority_id $authority_id]

            aa_true "Did get_parameter return the correct value?" [string equal $values "bar"]
        }
}

aa_register_case auth_driver_set_parameter_value {
    Test the auth::driver::set_parameter_value proc.

    @author Simon Carstensen (simon@collaboraid.biz)
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {
            
            db_1row select_vars {
                select auth_impl_id as impl_id,
                       authority_id
                from   auth_authorities
                where  short_name = 'local'
            }

            set key "foo"
            set value "bar"

            db_dml insert_test_parameter {
                insert into auth_driver_params (
                    impl_id, authority_id, key, value
                 ) values (
                    :impl_id, :authority_id, :key, :value
                 )
            }

            set new_value "new_bar"

            auth::driver::set_parameter_value \
                -impl_id $impl_id \
                -authority_id $authority_id \
                -parameter $key \
                -value $new_value
        
            set actual_value [db_string select_value {
                select value 
                from   auth_driver_params
                where  impl_id = :impl_id
                and    authority_id = :authority_id
                and    key = :key
            }]

            aa_equals "Value should be $new_value after update" $new_value $actual_value
        }
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

ad_proc -private auth::test::get_password_vars {
    {-array_name:required} 
} {
    Get test vars for test case.
} {
    upvar $array_name test_vars

    db_1row select_vars {} -column_array test_vars
}
