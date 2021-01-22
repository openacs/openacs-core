ad_library {
    Automated tests.

    @author Peter Marklund
    @creation-date 21 August 2003
    @cvs-id $Id$
}

aa_register_case \
    -cats {api}\
    auth_authenticate {
    Test the auth::authenticate proc.
} {    

    # Initialize variables
    set username "auth_create_user1"
    set password "changeme"

    aa_run_with_teardown \
        -rollback \
        -test_code {

            array set result [auth::create_user \
                                  -username $username \
                                  -email "auth_create_user1@test_user.com" \
                                  -first_names "Test" \
                                  -last_name "User" \
                                  -password $password \
                                  -secret_question "no_question" \
                                  -secret_answer "no_answer"]
            
            if { ![aa_equals "creation_status for successful creation" $result(creation_status) "ok"] } {
                aa_log "Creation result: [array get result]"
            }

            set user_id [acs_user::get_by_username -username $username]

            # Successful authentication
            array unset result
            array set result [auth::authenticate \
                                  -no_cookie \
                                  -username $username \
                                  -password $password]

            aa_log "Result: [array get result]"
    
            aa_equals "auth_status for successful authentication" $result(auth_status) "ok"

            # Failed authentications
            # Incorrect password
            array unset auth_info
            array set auth_info \
                [auth::authenticate \
                     -no_cookie \
                     -username $username \
                     -password "blabla"]

            aa_equals "auth_status for bad password authentication" $auth_info(auth_status) "bad_password"
            aa_true "auth_message for bad password authentication" [expr {$auth_info(auth_message) ne ""}]

            # Blank password
            array unset auth_info
            array set auth_info \
                [auth::authenticate \
                     -no_cookie \
                     -username $username \
                     -password ""]

            aa_equals "auth_status for blank password authentication" $auth_info(auth_status) "bad_password"
            aa_true "auth_message for blank password authentication" [expr {$auth_info(auth_message) ne ""}]

            # Incorrect username
            array unset auth_info
            array set auth_info \
                [auth::authenticate \
                     -no_cookie \
                     -username "blabla" \
                     -password $password]

            aa_equals "auth_status for bad username authentication" $auth_info(auth_status) "no_account"
            aa_true "auth_message for bad username authentication" [expr {$auth_info(auth_message) ne ""}]

            # Blank username
            array unset auth_info
            array set auth_info \
                [auth::authenticate \
                     -no_cookie \
                     -username "" \
                     -password $password]

            aa_equals "auth_status for blank username authentication" $auth_info(auth_status) "auth_error"
            aa_true "auth_message for blank username authentication" [expr {$auth_info(auth_message) ne ""}]

            # Authority bogus
            array unset auth_info
            array set auth_info \
                [auth::authenticate \
                     -no_cookie \
                     -authority_id -123 \
                     -username $username \
                     -password $password]

            aa_equals "auth_status for bad authority_id authentication" $auth_info(auth_status) "failed_to_connect"
            aa_true "auth_message for bad authority_id authentication" [expr {$auth_info(auth_message) ne ""}]

            # Closed account status
            set closed_states {banned rejected "needs approval" deleted}
            foreach closed_state $closed_states {
                acs_user::change_state -user_id $user_id -state $closed_state

                # Successful authentication
                array unset auth_info
                array set auth_info \
                    [auth::authenticate \
                         -no_cookie \
                         -username $username \
                         -password $password]
    
                aa_equals "auth_status for '$closed_state' user" $auth_info(auth_status) "ok"
                if {$auth_info(auth_status) eq "ok"} {
                    # Only perform this test if auth_status is ok, otherwise account_status won't be set
                    aa_equals "account_status for '$closed_state' user" $auth_info(account_status) "closed"
                }
            }

            if { $user_id ne "" } {
                acs_user::delete -user_id $user_id
            }
    
            # Error handling    
            # TODO or too hard?
        }
}

aa_register_case \
    -cats {api} \
    auth_create_user {
    Test the auth::create_user proc.
} {

    # create_user returns ok when trying to create a user 
    # whose email already lives in the db. We should test 
    # against that

    aa_run_with_teardown \
        -rollback \
        -test_code {
            
            # Successful creation
            array set user_info [auth::create_user \
                                     -username "auth_create_user1" \
                                     -email "auth_create_user1@test_user.com" \
                                     -first_names "Test" \
                                     -last_name "User" \
                                     -password "changeme" \
                                     -secret_question "no_question" \
                                     -secret_answer "no_answer"]

            aa_true "returns creation_status" [info exists user_info(creation_status)]

            if { [info exists user_info(creation_status)] } {
                aa_equals "creation_status for successful creation" $user_info(creation_status) "ok"
                
                if { $user_info(creation_status) ne "ok" } {
                    aa_log "Element messages: '$user_info(element_messages)'"
                    aa_log "Element messages: '$user_info(creation_message)'"
                }
            }

            aa_false "No creation_message for successful creation" \
		[expr {[info exists user_info(creation_message)] && $user_info(creation_message) ne ""}]
            aa_true "returns user_id" [info exists user_info(user_id)]
            
            if { [info exists user_info(user_id)] } {         
                aa_true "returns integer user_id ([array get user_info])" [regexp {[1-9][0-9]*} $user_info(user_id)]
            }

            # Duplicate email and username
            array unset user_info
            array set user_info [auth::create_user \
                                     -username "auth_create_user1" \
                                     -email "auth_create_user1@test_user.com" \
                                     -first_names "Test3" \
                                     -last_name "User" \
                                     -password "changeme" \
                                     -secret_question "no_question" \
                                     -secret_answer "no_answer"]

            aa_equals "creation_status for duplicate email and username" $user_info(creation_status) "data_error"
            
            aa_true "element_messages exists" [info exists user_info(element_messages)]
            if { [info exists user_info(element_messages)] && $user_info(element_messages) ne "" } {
                array unset elm_msgs
                array set elm_msgs $user_info(element_messages)
                aa_true "element_message for username exists" \
		    [expr {[info exists elm_msgs(username)] && $elm_msgs(username) ne ""}]
                aa_true "element_message for email exists" \
		    [expr {[info exists elm_msgs(email)] && $elm_msgs(email) ne ""}]
            }
            set user_id [acs_user::get_by_username -username auth_create_user1]
            if { $user_id ne "" } {
                acs_user::delete -user_id $user_id
            }
            
            # Missing first_names, last_name, email
            array unset user_info
            array set user_info [auth::create_user \
                                     -username "auth_create_user2" \
                                     -email "" \
                                     -first_names "" \
                                     -last_name "" \
                                     -password "changeme" \
                                     -secret_question "no_question" \
                                     -secret_answer "no_answer"]
            
            aa_equals "creation_status is data_error" $user_info(creation_status) "data_error" 
            
            aa_true "element_messages exists" [info exists user_info(element_messages)]
            if { [info exists user_info(element_messages)] && $user_info(element_messages) ne "" } {
                array unset elm_msgs
                array set elm_msgs $user_info(element_messages)

                if { [aa_true "element_message(email) exists" \
			  [expr {[info exists elm_msgs(email)] && $elm_msgs(email) ne ""}] ]} {
                    aa_log "element_message(email) = $elm_msgs(email)"
                }
                if { [aa_true "element_message(first_names) exists" [info exists elm_msgs(first_names)] ]} {
                    aa_log "element_message(first_names) = $elm_msgs(first_names)"
                }
                if { [aa_true "element_message(last_name) exists" [info exists elm_msgs(last_name)] ]} {
                    aa_log "element_message(last_name) = $elm_msgs(last_name)"
                }
            }
            set user_id [acs_user::get_by_username -username auth_create_user2]
            if { $user_id ne "" } {
                acs_user::delete -user_id $user_id
            }
            
            # Malformed email
            array unset user_info
            array set user_info [auth::create_user \
                                     -username [ad_generate_random_string] \
                                     -email "not an email" \
                                     -first_names "[ad_generate_random_string]<[ad_generate_random_string]" \
                                     -last_name "[ad_generate_random_string]<[ad_generate_random_string]" \
                                     -password [ad_generate_random_string] \
                                     -secret_question [ad_generate_random_string] \
                                     -secret_answer [ad_generate_random_string]]
            
            aa_equals "creation_status is data_error" $user_info(creation_status) "data_error" 
            
            aa_true "element_messages exists" [info exists user_info(element_messages)]
            if { [info exists user_info(element_messages)] && $user_info(element_messages) ne "" } {
                array unset elm_msgs
                array set elm_msgs $user_info(element_messages)

                if { [aa_true "element_message(email) exists" [info exists elm_msgs(email)]] } {
                    aa_log "element_message(email) = $elm_msgs(email)"
                }
                if { [aa_true "element_message(first_names) exists" [info exists elm_msgs(first_names)]] } {
                    aa_log "element_message(first_names) = $elm_msgs(first_names)"
                }
                if { [aa_true "element_message(last_name) exists" [info exists elm_msgs(last_name)]] } {
                    aa_log "element_message(last_name) = $elm_msgs(last_name)"
                }
            }
            
        } 
}

aa_register_case \
    -cats {db api smoke} \
    auth_confirm_email {
    Test the auth::set_email_verified proc.
} {
    set user_id [ad_conn user_id]

    aa_run_with_teardown \
        -rollback \
        -test_code {
            db_dml update { update users set email_verified_p = 'f' where user_id = :user_id }
            acs_user::flush_cache -user_id $user_id
   
            aa_equals "email should be not verified" [acs_user::get_element -user_id $user_id -element email_verified_p] "f"
            
            auth::set_email_verified -user_id $user_id
            
            aa_equals "email should be verified" [acs_user::get_element -user_id $user_id -element email_verified_p] "t"
            acs_user::flush_cache -user_id $user_id
        }
}

aa_register_case  \
    -cats {api smoke} \
    -error_level {warning} \
    auth_get_registration_elements {
    Test the auth::get_registration_elements proc
} {
    array set element_array [auth::get_registration_elements]

    aa_log "Elements array: '[array get element_array]'"

    aa_true "there is more than one required element" [expr {[llength $element_array(required)] > 0}]
    aa_true "there is more than one optional element" [expr {[llength $element_array(optional)] > 0}]
}

aa_register_case  \
    -cats {api smoke} \
    -error_level {warning} \
    auth_get_registration_form_elements {
    Test the auth::get_registration_form_elements proc
} {
    set form_elements [auth::get_registration_form_elements]

    aa_true "Form elements are not empty: $form_elements" [expr {$form_elements ne ""}] 
}

###########
#
# Password API
#
###########

aa_register_case  \
    -cats {api smoke} \
    auth_password_get_change_url {
    Test the auth::password::get_change_url proc.
} {

    # Test whether auth::password::get_change_url returns the correct URL to redirect when "change_pwd_url" is set. 
    auth::test::get_password_vars -array_name test_vars

    if { [info exists test_vars(user_id)] } {
        set change_pwd_url [auth::password::get_change_url -user_id $test_vars(user_id)]
        aa_true "Check that auth::password::get_change_url returns correct redirect URL when change_pwd_url is not null" \
            [regexp {password-update} $change_pwd_url]            
    }
}

aa_register_case  \
    -cats {api smoke} \
    -error_level {warning} \
    auth_password_can_change_p {
    Test the auth::password::can_change_p proc.
} {
    auth::test::get_password_vars -array_name test_vars
    
    aa_equals "Should return 1 when CanChangePassword is true for the local driver " \
        [auth::password::can_change_p -user_id $test_vars(user_id)] \
        "1"
}

aa_register_case  \
    -cats {api} \
    auth_password_change {
    Test the auth::password::change proc.
} {
    aa_stub acs_mail_lite::send {
        set ::ns_sendmail_to $to_addr
    }

    aa_run_with_teardown \
        -rollback \
        -test_code {         
            # create user we'll use for testing
            set email "test2@user.com"
            array set user_info [auth::create_user \
                    -email $email \
                    -first_names "Test" \
                    -last_name "User" \
                    -password "changeme" \
                    -secret_question "no_question" \
                    -secret_answer "no_answer"]
            set user_id $user_info(user_id)

            set ::ns_sendmail_to {ns_sendmail_UNCALLED}

            parameter::set_value -parameter EmailAccountOwnerOnPasswordChangeP  -package_id [ad_acs_kernel_id] -value 1
            aa_true "Send email" [parameter::get -parameter EmailAccountOwnerOnPasswordChangeP -package_id [ad_acs_kernel_id] -default 1]

            # password_status "ok"
            set old_password "changeme"
            set new_password "changedyou"
            array set auth_info [auth::password::change \
                                     -user_id $user_id \
                                     -old_password $old_password \
                                     -new_password $new_password]
            aa_equals "Should return 'ok'" \
                $auth_info(password_status) \
                "ok"
            
            # Check that user gets email about changed password
            aa_equals "Email sent to user" $::ns_sendmail_to $email
            set ::ns_sendmail_to {}

            # check that the new password is actually set correctly
            set password_correct_p [ad_check_password $user_id $new_password]
            aa_equals "check that the new password is actually set correctly" \
                $password_correct_p \
                "1"

            ad_parameter_cache -delete [ad_acs_kernel_id] EmailAccountOwnerOnPasswordChangeP
            if { $user_id ne "" } {
                acs_user::delete -user_id $user_id
            }
        }
}

aa_register_case  \
    -cats {api smoke} \
    auth_password_recover {
    Test the auth::password::recover_password proc.
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
            aa_true "non-empty message" [expr {$password_result(password_message) ne ""}] 
        }
}

aa_register_case  \
    -cats {api smoke} \
    auth_password_get_forgotten_url {
    Test the auth::password::get_forgotten_url proc.
} {
    auth::test::get_password_vars -array_name test_vars    

    # With user info
    set url [auth::password::get_forgotten_url -authority_id $test_vars(authority_id) -username $test_vars(username)]
    aa_true "there is a local recover-password page with user info ($url)" [regexp {recover-password} $url]

    set url [auth::password::get_forgotten_url -authority_id $test_vars(authority_id) -username $test_vars(username) -remote_only]
    aa_equals "cannot get remote url with missing forgotten_pwd_url" $url ""

    # Without user info
    set url [auth::password::get_forgotten_url -authority_id "" -username "" -remote_only]
    aa_equals "cannot get remote url without user info" $url ""

    set url [auth::password::get_forgotten_url -authority_id "" -username ""]
    aa_true "there is a local recover-password page without user info" [regexp {recover-password} $url]
}

aa_register_case  \
    -cats {api smoke} \
    auth_password_retrieve {
    Test the auth::password::retrieve proc.
} {
    auth::test::get_password_vars -array_name test_vars    
    array set result [auth::password::retrieve \
                          -authority_id $test_vars(authority_id) \
                          -username $test_vars(username)]
    
    aa_equals "retrieve pwd from local auth" $result(password_status) "ok"
    aa_true "must have message on failure" [expr {$result(password_message) ne ""}] 
}

aa_register_case  \
    -cats {api} \
    auth_password_reset {
    Test the auth::password::reset proc.
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
                email "test_username@test.test"
                password "test_password"
                first_names "test_first_names"
                last_name  "test_last_name"
            }

            array set create_result [auth::create_user \
                                         -username $test_user(username) \
                                         -email $test_user(email) \
                                         -password $test_user(password) \
                                         -first_names $test_user(first_names) \
                                         -last_name $test_user(last_name) \
                                         -secret_question "foo" \
                                         -secret_answer "bar"]
            aa_equals "status should be ok for creating user" $create_result(creation_status) "ok"
            if { $create_result(creation_status) ne "ok" } {
                aa_log "Create-result: '[array get create_result]'"
            }
                
            array set reset_result [auth::password::reset \
                                        -authority_id [auth::authority::local] \
                                        -username $test_user(username)] 
            aa_equals "status should be ok for reseting password" $reset_result(password_status) "ok"
            aa_true "Result contains new password" [info exists reset_result(password)]
            
            if { [info exists reset_result(password)] } {
                array set auth_result [auth::authentication::Authenticate \
                                           -username $test_user(username) \
                                           -authority_id [auth::authority::local] \
                                           -password $reset_result(password)]
                aa_equals "can authenticate with new password" $auth_result(auth_status) "ok"
                
                array unset auth_result
                array set auth_result [auth::authentication::Authenticate \
                                           -username $test_user(username) \
                                           -authority_id [auth::authority::local] \
                                           -password $test_user(password)]
                aa_false "cannot authenticate with old password" [string equal $auth_result(auth_status) "ok"]
            }
            set user_id [acs_user::get_by_username -username $test_user(username)]
            if { $user_id ne "" } {
                acs_user::delete -user_id $user_id
            }
        }
}

###########
#
# Authority Management API
#
###########

aa_register_case  \
    -cats {api db} \
    auth_authority_api {
    Test the auth::authority::create, auth::authority::edit, and auth::authority::delete procs.
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {

            # Add authority and test that it was added correctly.
            array set columns {
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
                get_doc_impl_id ""
                process_doc_impl_id ""
                batch_sync_enabled_p "f"
            }
            set columns(short_name) [ad_generate_random_string]
            
            set authority_id [auth::authority::create -array columns]

            set authority_added_p [db_string authority_added_p {
                select count(*) from auth_authorities where authority_id = :authority_id
            } -default "0"]

            aa_true "was the authority added?" $authority_added_p

            aa_log "authority_id = '$authority_id'"

            # Edit authority and test that it has actually changed.
            array set columns {
                pretty_name "Test authority2"
                help_contact_text "Blah blah2"
                enabled_p "f"
                sort_order "1001"
                forgotten_pwd_url "foobar.com"
                change_pwd_url "foobar.com"
                register_url "foobar.com"
            }
            set columns(short_name) [ad_generate_random_string]

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


aa_register_case  \
    -cats {api} \
    auth_driver_get_parameter_values {
    Test the auth::driver::set_parameter_values proc.
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {
            auth::authority::get -authority_id [auth::authority::local] -array authority

            set sync_retrieve_impl_id [acs_sc::impl::get_id -owner acs-authentication -name HTTPGet]

            array set parameters_array [auth::driver::get_parameters -impl_id $sync_retrieve_impl_id]

            set parameters [array names parameters_array]

            aa_true "List of parameters is not empty" [expr {[llength $parameters] != 0}]

            array set values [list]

            # Set the values
            foreach parameter $parameters {
                set value($parameter) [ad_generate_random_string]
                
                # Set a parameter value
                auth::driver::set_parameter_value \
                    -authority_id $authority(authority_id) \
                    -impl_id $sync_retrieve_impl_id \
                    -parameter $parameter \
                    -value $value($parameter)
            }
            
            # Get and verify values
            
            array set retrieved_value [auth::driver::get_parameter_values \
                                            -authority_id $authority(authority_id) \
                                            -impl_id $sync_retrieve_impl_id]
            
            foreach parameter $parameters {
                if { [aa_true "Parameter $parameter exists" [info exists retrieved_value($parameter)]] } {
                    aa_equals "Parameter value retrieved is the one we set" $retrieved_value($parameter) $value($parameter)
                }
                array unset retrieved_value $parameter
            }
            aa_true "Only the right parameters were retrieved" [expr {[array size retrieved_value] == 0}]
        }
}

aa_register_case  \
    -cats {api} \
    auth_use_email_for_login_p {
    Test auth::UseEmailForLoginP
} {
    aa_stub auth::get_register_authority {
        return [auth::authority::local]
    }

    aa_run_with_teardown \
        -rollback \
        -test_code {
            # Test various values to see that it doesn't break

            parameter::set_value -parameter UseEmailForLoginP -package_id [ad_acs_kernel_id] -value 0
            aa_false "Param UseEmailForLoginP 0 -> false" [auth::UseEmailForLoginP]

            array set elms [auth::get_registration_elements]
            aa_false "Registration elements do contain username" [expr {"username" ni [concat $elms(required) $elms(optional)]}]

            parameter::set_value -parameter UseEmailForLoginP -package_id [ad_acs_kernel_id] -value {}
            aa_true "Param UseEmailForLoginP {} -> true" [auth::UseEmailForLoginP]

            # "foo" is an invalid value, it can't be true
            parameter::set_value -parameter UseEmailForLoginP -package_id [ad_acs_kernel_id] -value {foo}
            aa_false "Param UseEmailForLoginP foo -> false" [auth::UseEmailForLoginP]
            
            # Test login/registration
            
            parameter::set_value -parameter UseEmailForLoginP -package_id [ad_acs_kernel_id] -value 1
            aa_true "Param UseEmailForLoginP 1 -> true" [auth::UseEmailForLoginP]

            # GetElements
            array set elms [auth::get_registration_elements]
            aa_true "Registration elements do NOT contain username" [expr {"username" ni [concat $elms(required) $elms(optional)]}]
            
            # Create a user with no username
            set email [string tolower "[ad_generate_random_string]@foobar.com"]
            set password [ad_generate_random_string]

            array set result [auth::create_user \
                                  -email $email \
                                  -password $password \
                                  -first_names [ad_generate_random_string] \
                                  -last_name [ad_generate_random_string] \
                                  -secret_question [ad_generate_random_string] \
                                  -secret_answer [ad_generate_random_string] \
                                  -screen_name [ad_generate_random_string]]

            aa_equals "Registration OK" $result(creation_status) "ok"

            # Authenticate as that user
            array unset result
            array set result [auth::authenticate \
                                  -email $email \
                                  -password $password \
                                  -no_cookie]
            
            aa_equals "Authentication OK" $result(auth_status) "ok"
            
        }
}

aa_register_case  \
    -cats {api} \
    auth_email_on_password_change {
    Test acs-kernel.EmailAccountOwnerOnPasswordChangeP parameter
} {
    aa_stub acs_mail_lite::send {
        set ::ns_sendmail_to $to_addr
    }

    aa_run_with_teardown \
        -rollback \
        -test_code {
            parameter::set_value -parameter EmailAccountOwnerOnPasswordChangeP -package_id [ad_acs_kernel_id] -value 1
            
            set ::ns_sendmail_to {}
           
            # Create a dummy local user
            set username [ad_generate_random_string]
            set email [string tolower "[ad_generate_random_string]@foobar.com"]
            set password [ad_generate_random_string]

            array set result [auth::create_user \
                                  -username $username \
                                  -email $email \
                                  -password $password \
                                  -first_names [ad_generate_random_string] \
                                  -last_name [ad_generate_random_string] \
                                  -secret_question [ad_generate_random_string] \
                                  -secret_answer [ad_generate_random_string] \
                                  -screen_name [ad_generate_random_string]]
            
            aa_equals "Create user OK" $result(creation_status) "ok"

            set user_id $result(user_id)

            aa_log "auth_id = [db_string sel { select authority_id from users where user_id = :user_id }]"

            
            # Change password
            array unset result
            set new_password [ad_generate_random_string]
            array set result [auth::password::change \
                                  -user_id $user_id \
                                  -old_password $password \
                                  -new_password $new_password]
            if { ![aa_equals "Password change OK" $result(password_status) "ok"] } {
                aa_log "Message was: $result(password_message)"
            }
            
            # Check that we get email
            aa_equals "Email sent to user" $::ns_sendmail_to $email
            set ::ns_sendmail_to {ns_sendmail_UNCALLED}

            # Set parameter to false
            parameter::set_value -parameter EmailAccountOwnerOnPasswordChangeP -package_id [ad_acs_kernel_id] -value 0

            # Change password
            array unset result
            set new_new_password [ad_generate_random_string]
            array set result [auth::password::change \
                                  -user_id $user_id \
                                  -old_password $new_password \
                                  -new_password $new_new_password]
            aa_equals "Password change OK" $result(password_status) "ok"
            
            # Check that we do not get an email
            aa_equals "Email NOT sent to user" $::ns_sendmail_to {ns_sendmail_UNCALLED}

            ad_parameter_cache -delete [ad_acs_kernel_id] EmailAccountOwnerOnPasswordChangeP
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

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
