ad_library {
    Tcl API for authentication, account management, and password management,

    @author Lars Pind (lars@collaobraid.biz)
    @creation-date 2003-05-13
    @cvs-id $Id$
}

namespace eval auth {}
namespace eval auth::authentication {}
namespace eval auth::password {}
namespace eval auth::registration {}



#####
#
# auth namespace public procs
#
#####

ad_proc -public auth::require_login {} {
    If the current session is not authenticated, redirect to the 
    login page, and aborts the current page script.
    Otherwise, returns the user_id of the user logged in.
    Use this in a page script to ensure that only registered and authenticated 
    users can execute the page, for example for posting to a forum.

    @return user_id of user, if the user is logged in. 
            Otherwise will issue a returnredirect and abort the current page.

    @see ad_script_abort
} {
    return [ad_maybe_redirect_for_registration]
}

ad_proc -public auth::authenticate {
    {-authority_id ""}
    {-username:required}
    {-password:required}
} {
    Try to authenticate and login the user forever by validating the username/password combination, 
    and return authentication and account status codes.    
    
    @param authority_id The ID of the authority to ask to verify the user. Defaults to local authority.
    @param username Authority specific username of the user.
    @param passowrd The password as the user entered it.
    
    @return Array list with the following entries:
    
    <ul>
      <li> auth_status:     Whether authentication succeeded. 
                            ok, no_account, bad_password, auth_error, failed_to_connect 
      <li> auth_message:    Human-readable message about what went wrong. Guaranteed to be set if auth_status is not ok. 
                            Should be ignored if auth_status is ok. May contain HTML.

      <li> account_status:  Account status from authentication server. 
                            ok, closed.
      <li> account_message: Human-readable message about account status. Guaranteed to be set if auth_status is not ok. 
                            If non-empty, must be relayed to the user regardless of account_status. May contain HTML.
                            This proc is responsible for concatenating any remote and/or local account messages into 
                            one single message which can be displayed to the user.

      <li> user_id:         Set to local user_id if auth_status is ok.
    </ul>

} {
    # Default to local authority
    if { [empty_string_p $authority_id] } {
        set authority_id [auth::authority::local]
    }

    # Implementation note: 
    # Invoke the service contract
    # Provide canned strings for auth_message and account_message if not returned by SC implementation.
    # Concatenate remote account message and local account message into one logical understandable message.
    # Same with account status: only ok if both are ok.

    array set auth_info [auth::authentication::Authenticate \
                             -username $username \
                             -authority_id $authority_id \
                             -password $password]

    # Returns:
    #   auth_info(auth_status) 
    #   auth_info(auth_message) 
    #   auth_info(account_status) 
    #   auth_info(account_message) 
    
    if { [string equal $auth_info(auth_status) "ok"] && [string equal $auth_info(account_status) "ok"] } {

        # LARS:
        # Note: This has changed in the design to not throw away remote account status

        # WRONG! External account status was ok, so we don't need that info anymore
        # We'll replace it with local account status below
        array unset auth_info account_status
        array unset auth_info account_message

        # Map to row in local users table
        array set auth_info [auth::get_local_account \
                           -username $username \
                           -authority_id $authority_id]

        # Returns: 
        #   auth_info(account_status)
        #   auth_info(account_message)  
        #   auth_info(user_id)
        # These are appended to the existing entries in auth_info
        
        if { [string equal $auth_info(account_status) "ok"] } {
            auth::issue_login -user_id $auth_info(user_id)
        }
    }
    
    return [array get auth_info]
}

ad_proc -private auth::issue_login {
    {-user_id:required}
    {-persistent:boolean}
} {
    Issue the login cookie.
} {
    ad_user_login -forever=$persistent_p $user_id
}

ad_proc -public auth::create_user {
    {-username:required}
    {-password:required}
    {-first_names ""}
    {-last_name ""}
    {-email ""}
    {-url ""}
    {-secret_question ""}
    {-secret_answer ""}
    {-email_verified_p "t"} 
    {-member_state "approved"}
} {
    Create a user, and return creation status and account status.
    
    @param email_verified_p Whether the local account considers the email to be verified or not.
    @param member_state     Whether the local account has been approved.

    @return Array list containing the following entries:

    <ul>
      <li> creation_status:  ok, data_error, reg_error, failed_to_connect. Says whether user creation succeeded.
      <li> creation_message: Information about the problem, to be relayed to the user. May contain HTML.
      <li> element_messages: list of (element_name, message, element_name, message, ...) of 
                             errors on the individual elements (username, password, first_names, ...), 
                             to be relayed on to the user. If creation_status is not ok, then either 
                             creation_message or element_messages is guaranteed to be non-empty. Cannot contain HTML.
      <li> account_status:   ok, closed. Only set if creation_status was ok, this says whether the newly created account 
                             is ready for use or not. For example, we may require approval, in which case the account 
                             would be created but closed.
      <li> account_message:  A human-readable explanation of why the account was closed. May include HTML, and thus shouldn't
                             be quoted. Guaranteed to be non-empty if account_status is not ok.
    </ul>
} {
     # Implementation note:
     # just call auth::local::registration::Register for now

     # If we ever create remote users, make sure we concatenate any account messages and local account messages
     # into one combined message.
     # Same for account_status (only ok if both are ok)

     set authority_id [auth::authority::local]

     auth::registration::Register \
         -authority_id $authority_id \
         -username $username \
         -password $password \
         -first_names $first_names \
         -last_name $last_name \
         -email $email \
         -url $url \
         -secret_question $secret_question \
         -secret_answer $secret_answer
}

ad_proc -public auth::get_registration_elements {
    {-authority_id ""}
} {
    Get the list of required/optional elements for user registration.
    
    @return Array-list with two entries, both being a subset of 
            (username, password, first_names, last_name, email, url, secret_question, secret_answer).
            
    <ul>
      <li> required: a list of required elements
      <li> optional: a list of optional elements
    </ul>
            
} {
    if { [empty_string_p $authority_id] } {
        set authority_id [auth::authority::local]
    }

    return [auth::registration::GetElements -authority_id $authority_id]
}

ad_proc -public auth::get_registration_form_elements {
    {-authority_id ""}
} {
    Returns a list of elements to be included in the -form chunk of an ad_form form.
    All possible elements will always be present, but those that shouldn't be displayed 
    will be hidden and have a hard-coded empty string value.
} {
    if { [empty_string_p $authority_id] } {
        set authority_id [auth::authority::local]
    }

    array set data_types {
        username text
        email text
        first_names text
        last_name text
        url text
        password text
        secret_question text
        secret_answer text
    }

    array set widgets {
        username text 
        email test
        first_names text
        last_name text
        url text
        password text 
        secret_question text
        secret_answer text
    }
    
    array set labels [list \
        username [_ acs-subsite.Username] \
        email [_ acs-subsite.Your_email_address] \
        first_names [_ acs-subsite.First_names] \
        last_name [_ acs-subsite.Last_name] \
        url [_ acs-subsite.lt_Personal_Home_Page_UR] \
        password [_ acs-subsite.Your_password] \
        secret_question [_ acs-subsite.Question] \
        secret_answer [_ acs-subsite.Answer] \
    ]

    array set html {
        username {size 30}
        email {size 30}
        first_names {size 20}
        last_name {size 25}
        url {size 50 value "http://"}
        password {size 20}
        secret_question {size 30}
        secret_answer {size 30}
    }
    
    array set element_info [auth::get_registration_elements -authority_id $authority_id]

    set form_elements [list]
    foreach element [concat $element_info(required) $element_info(optional)] {
        set form_element [list]

        # The header with name, datatype, and widget
        set form_element_header "${element}:$data_types($element)($widgets($element))"
        set optional_p [expr [lsearch -exact $element_info(optional) $element] != -1]
        if { $optional_p } {
            append form_element_header ",optional"
        }
        lappend form_element $form_element_header

        # The label
        lappend form_element [list label $labels($element)]

        # HTML
        lappend form_element [list html $html($element)]

        # The form element is finished - add it to the list
        lappend form_elements $form_element
    }

    return $form_elements
}

ad_proc -public auth::create_local_account {
    {-user_id ""}
    {-authority_id ""}
    {-username:required}
    {-first_names:required}
    {-last_name:required}
    {-email:required}
    {-url ""}
    {-member_state "approved"}
    {-email_verified_p "t"}
} {
    Create the local account for a user.
} {

    # TODO: implement
}

ad_proc -public auth::confirm_email {
    {-user_id:required}
} {
    Update an OpenACS record with the fact that the email address on
    record was verified.
} {
    db_dml set_email_verified {
        update users 
        set email_verified_p = 't'
        where user_id = :user_id
    }
}

#####
#
# auth namespace private procs
#
#####

ad_proc -private auth::get_local_account {
    {-username:required}
    {-authority_id ""}
} {
    Get the user_id of the local account for the given 
    username and domain combination.

    @param username The username to find

    @param authority_id The ID of the authority to ask to verify the user. Leave blank for local authority.
} {
    array set auth_info [list]
    
    # Will return:
    #   auth_info(account_status)
    #   auth_info(account_message)  
    #   auth_info(user_id)

    if { [empty_string_p $authority_id] } {
        set authority_id [auth::authority::local]
    }

    set account_found_p [db_0or1row select_user_info { 
        select user_id,
               email,
               member_state,
               email_verified_p
        from   cc_users 
        where  username = :username
        and    authority_id = :authority_id
    }]

    if { !$account_found_p } {
        # Local user account doesn't exist
        set auth_info(account_status) "no_account"
        set auth_info(account_message) {}
        return [array get auth_info]
    }

    # Check local account status

    # Initialize to 'closed', because most cases below mean the account is closed
    set auth_info(account_status) "closed"

    # system_name is used in some of the I18N messages
    set system_name [ad_system_name]    
    switch $member_state {
        "approved" {
            if { $email_verified_p == "f" } {
                set row_id [db_string rowid_for_email {
                    select rowid from users where user_id = :user_id
                }]
                
                # Send email verification email to user
                set confirmation_url "[ad_url]/register/email-confirm?[export_vars { row_id }]"
                with_catch errmsg {
                    ns_sendmail \
                        $email \
                        $notification_address \
                        "[_ acs-subsite.lt_Welcome_to_system_nam]" \
                        "[_ acs-subsite.lt_To_confirm_your_regis]"
                }
                
                set auth_info(account_message) "<p>[_ acs-subsite.lt_Registration_informat]</p><p>[_ acs-subsite.lt_Please_read_and_follo]</p>"
            } else {
                set auth_info(account_status) "ok"
            }
        }
        "banned" { 
            set auth_info(account_message) [_ acs-subsite.lt_Sorry_but_it_seems_th]
        }
        "deleted" {  
            set auth_info(account_message) "[_ acs-subsite.Welcome_Back_1] <a href=\"restore-user?[export_vars { user_id }]\">[_ acs-subsite.to_site_link_1]</a>."
        }
        "rejected" - "needs_approval" {
            set auth_info(account_message) "<p>[_ acs-subsite.lt_registration_request_submitted]</p><p>[_ acs-subsite.Thank_you]</p>"
        }
        default {
            set auth_info(account_message) "There was a problem authenticating the account: $user_id. Most likely, the database contains users with no user_state."
            ns_log Warning "Problem with registration state machine on user-login.tcl"
        }
    }
    set auth_info(user_id) $user_id

   return [array get auth_info]    
}

#####
#
# auth::authentication
#
#####

ad_proc -private auth::authentication::Authenticate {
    {-authority_id ""}
    {-username:required}
    {-password:required}
} {
    Invoke the Authenticate service contract operation for the given authority.

    @param authority_id The ID of the authority to ask to verify the user. Defaults to local authority.
    @param username Username of the user.
    @param passowrd The password as the user entered it.    
} {
    if { [empty_string_p $authority_id] } {
        set authority_id [auth::authority::local]
    } {
        # Check that the authority exists
        set authority_exists_p [db_string authority_exists_p {
            select count(*)
            from auth_authorities
            where authority_id = :authority_id
        }]

        if { ! $authority_exists_p } {
            set auth_info(auth_status) auth_error
            set auth_info(auth_message) "Internal error - authority with id $authority_id does not exist"

            return [array get auth_info]
        }
    }

    # TODO:
    # Implement parameters

    set impl_id [auth::authority::get_element -authority_id $authority_id -element "auth_impl_name"]
    if { [empty_string_p $impl_id] } {
        # Invalid authority
        return {}
    }

    return [acs_sc::invoke \
                -contract "auth_authentication" \
                -impl $impl_id \
                -operation Authenticate \
                -call_args [list $username $password [list]]]
}

#####
#
# auth::registration
#
#####

ad_proc -private auth::registration::Register {
    {-authority_id ""}
    {-username:required}
    {-password:required}
    {-first_names ""}
    {-last_name ""}
    {-email ""}
    {-url ""}
    {-secret_question ""}
    {-secret_answer ""}
} {
    Invoke the Register service contract operation for the given authority.

    @authority_id Id of the authority. Defaults to local authority.
    @url Any URL (homepage) associated with the new user
    @secret_question Question to ask on forgotten password
    @secret_answer Answer to forgotten password question
} {
    if { [empty_string_p $authority_id] } {
        set authority_id [auth::authority::local]
    }

    # TODO:
    # Implement parameters

    return [acs_sc::invoke \
                -contract "auth_registration" \
                -impl [auth::authority::get_element -authority_id $authority_id -element "auth_impl_name"] \
                -operation Register \
                -call_args [list [list] \
                                 $username \
                                 $authority_id \
                                 $first_names \
                                 $last_name \
                                 $email \
                                 $url \
                                 $password \
                                 $secret_question \
                                 $secret_answer]]
}

ad_proc -private auth::registration::GetElements {
    {-authority_id ""}    
} {

    @author Peter Marklund
} {
    if { [empty_string_p $authority_id] } {
        set authority_id [auth::authority::local]
    }

    # TODO:
    # Implement parameters

    return [acs_sc::invoke \
                -contract "auth_registration" \
                -impl [auth::authority::get_element -authority_id $authority_id -element "auth_impl_name"] \
                -operation GetElements \
                -call_args [list [list]]]
}


#####
#
# auth::password public procs
#
#####

ad_proc -public auth::password::get_change_url {
    {-user_id:required}
} {
    Returns the URL to redirect to for changing passwords. If the
    user's authority has a "change_pwd_url" set, it'll return that,
    otherwise it'll return a link to /user/password-update under the
    nearest subsite.

    @param user_id The ID of the user whose password you want to change.

    @return A URL that can be linked to for changing password.
} {
    db_1row select_vars {
        select aa.change_pwd_url,
               u.username
        from auth_authorities aa,
             users u
        where aa.authority_id = u.authority_id
          and u.user_id = :user_id
    }

    # Interpolate any username variable in URL
    regsub -all "{username}" $change_pwd_url $username change_pwd_url
    
    # Default to the OpenACS change password URL
    if { [empty_string_p $change_pwd_url] } {
        set change_pwd_url "[subsite::get_element -element url]user/password-update?[export_vars { user_id }]"
    } 

    return $change_pwd_url
}

ad_proc -public auth::password::can_change_p {
    {-user_id:required}
} {
    Returns whether the given user change password. 
    This depends on the user's authority and the configuration of that authority. 
    
    @param user_id The ID of the user whose password you want to change.

    @return 1 if the user can change password, 0 otherwise.
} {
    # TODO: Should we use acs_user::get here? Can we cache that proc?
    set authority_id [db_string authority_id_from_user_id {
        select authority_id
        from users
        where user_id = :user_id
    }]

    return [auth::password::CanChangePassword -authority_id $authority_id]
}

ad_proc -public auth::password::change {
    {-user_id:required}
    {-old_password:required}
    {-new_password:required}
} {
    Change the user's password.

    @param user_id      The ID of the user whose password you want to change.

    @param old_password The current password of that user. This is required for security purposes.
    
    @param new_password The desired new password of the user.

    @return An array list with the following entries:

    <ul>

       <li> password_status: "ok", "no_account", "old_password_bad",
       "new_password_bad", "change_error", "failed_to_connect" </li>

       <li> password_message: A human-readable description of what
       went wrong. </li>

   </ul>
} {
    # TODO: Should we use acs_user::get here? Can we cache that proc?
    db_1row user_info {
        select authority_id,
               username
        from users
        where user_id = :user_id
    }

    return [auth::password::ChangePassword \
                -authority_id $authority_id \
                -username $username \
                -old_password $old_password \
                -new_password $new_password]
}

ad_proc -public auth::password::forgotten {
    {-authority_id:required}
    {-username:required}
} { 
    Handles forgotten passwords.

    @param authority_id The ID of the authority that the user is trying to log into.

    @param username The username that the user's trying to log in with.

    @return Array list with the following entries:

    <ul>
        <li> password_status: ok, no_support, failed_to_connect
        <li> password_message: Human-readable message to be relayed to the user. May contain HTML.
    </ul>
} {

    set forgotten_url [auth::password::get_forgotten_url \
                           -authority_id $authority_id \
                           -username $username]

    if { ![empty_string_p $forgotten_url] } {
        ad_returnredirect $forgotten_url
        ad_script_abort
    }

    set can_retrieve_p [auth::password::can_retrieve_p -authority_id $authority_id]
    set can_reset_p [auth::password::can_reset_p -authority_id $authority_id]
    if { $can_retrieve_p } {
        # Retrive password
        array set result [auth::password::retrieve \
                              -authority_id $authority_id \
                              -username $username]

        # Error handling needed here?
        # TODO

    } elseif { $can_reset_p } {
        # Reset password
        array set result [auth::password::reset \
                              -authority_id $authority_id \
                              -username $username]
 
        # Error handling needed here?
        # TODO

    } else {
        # Can't reset or retrieve - we give up
        set result(password_status) not_supported
        set result(password_message) [_ acs-subsite.sorry_forgotten_pwd]
    }

    if { [exists_and_not_null result(password)] } {
        # We have retrieved or reset a forgotten password that we should email to the user
        if { [catch {auth::password::email_password \
                         -username $username \
                         -password $result(password)} errmsg] } {
            
            # We could not inform the user of his email - we failed
            set result(password_status) "fail"
            set result(password_message) [auth::password::get_email_error_msg $errmsg]

        } else {
            # Successfully informed user of email
            set result(password_status) ok
            set result(password_message) [_ acs-subsite.Check_Your_Inbox]
        }
    }

    return [array get result]
}

ad_proc -public auth::password::get_forgotten_url {
    {-authority_id ""}
    {-username ""}
    {-remote_only:boolean}
} { 
    Returns the URL to redirect to for forgotten passwords. 
        
    @param authority_id The ID of the authority that the user is trying to log into.
    @param username The username that the user's trying to log in with.
    @param remote_only If provided, only return any remote URL (not on this server).

    @return A URL that can be linked to when the user has forgotten his/her password, 
            or the empty string if none can be found.
} {
    set have_user_id_p [expr ![empty_string_p $authority_id] && ![empty_string_p username]]

    if { $have_user_id_p } {
        # We have the user id

        set forgotten_pwd_url [db_string select_forgotten_pwd_url {
            select forgotten_pwd_url
            from auth_authorities
            where authority_id = :authority_id
        }]
        regsub -all "{username}" $forgotten_pwd_url $username forgotten_pwd_url


        if { [empty_string_p $forgotten_pwd_url] } {            
            if { ! $remote_only_p } {
                # If we can retrive or reset passwords we can use the local url
                # In remote mode we fail
                set can_retrieve_p [auth::password::can_retrieve_p -authority_id $authority_id]
                set can_reset_p [auth::password::can_reset_p -authority_id $authority_id]
                if { $can_retrieve_p || $can_reset_p } {
                    set forgotten_pwd_url "[subsite::get_element -element url]register/forgotten-password?[export_vars { authority_id username }]"
                }
            }
        }
    } else {
        # We don't have the user id

        if { $remote_only_p } {
            # Remote recovery requires username and authority so we fail
            set forgotten_pwd_url ""
        } else {            
            set forgotten_pwd_url "[subsite::get_element -element url]register/forgotten-password"
        }
    }
    
    return $forgotten_pwd_url
}

ad_proc -public auth::password::can_retrieve_p {
    {-authority_id:required}
} {
    Returns whether the given authority can retrive forgotten passwords. 
    
    @param authority_id The ID of the authority that the user is trying to log into.

    @return 1 if the authority allows retrieving passwords, 0 otherwise.
} {
    return [auth::password::CanRetrievePassword -authority_id $authority_id]
}

ad_proc -public auth::password::retrieve {
    {-authority_id:required}
    {-username:required}
} {
    Retrieve the user's password.

    @param authority_id The ID of the authority that the user is trying to log into.

    @param username The username that the user's trying to log in with.

    @return An array list with the following entries:

    <ul>

       <li> password_status: ok, no_account, not_supported,
       retrieve_error, failed_to_connect </li>

       <li> password_message: A human-readable message to be
       relayed to the user. May be empty if password_status is ok. May
       include HTML. 

       <li> password: The retrieved password. </li>

    </ul>
} {
    return [auth::password::RetrievePassword \
                -authority_id $authority_id \
                -username $username]
}

ad_proc -public auth::password::can_reset_p {
    {-authority_id:required}
} {
    Returns whether the given authority can reset forgotten passwords. 
    
    @param authority_id The ID of the authority that the user is trying to log into.

    @return 1 if the authority allows resetting passwords, 0 otherwise.
} {
    return [auth::password::CanResetPassword \
                -authority_id $authority_id]
}

ad_proc -public auth::password::reset {
    {-authority_id:required}
    {-username:required}
} {
    Reset the user's password, which means setting it to a new
    randomly generated password and inform the user of that new
    password.

    @param user_id      The ID of the user whose password you want to reset.

    @return An array list with the following entries:

    <ul>

       <li> password_status: ok, no_account, not_supported,
       reset_error, failed_to_connect </li>

       <li> password_message: A human-readable message to be
       relayed to the user. May be empty if password_status is ok. May
       include HTML. Could be empty if password_status is ok.

       <li> password: The new, automatically generated password. If no
       password is included in the return array, that means the new
       password has already been sent to the user somehow. If it is
       returned, it means that caller is responsible for informing the
       user of his/her new password.</li>

    </ul>
} { 
    array set result [auth::password::ResetPassword \
                          -authority_id $authority_id \
                          -username $username]

    if { [catch {auth::password::email_password \
                     -username $username \
                     -authority_id $authority_id \
                     -password $result(password)} errmsg] } {

        set result(password_status) "reset_error"
        set result(password_message) [auth::password::get_email_error_msg $errmsg]
    }

    return [array get result]
}

#####
#
# auth::password private procs
#
#####

ad_proc -private auth::password::email_password {
    {-username:required}
    {-authority_id ""}
    {-password:required}
} {
    Send an email to ther user with given username and authority with the new password.

    @return Does not return anything. Any errors caused by ns_sendmail are propagated

    @author Peter Marklund
} {

    set system_owner [ad_system_owner]
    set system_name [ad_system_name]
    set reset_password_url "[ad_url]/user/password-update?[export_vars {user_id {password_old $password}}]" 

    set subject "[_ acs-subsite.lt_Your_forgotten_passwo]"
    set body "[_ acs-subsite.Your_password]: $password"

    # TODO: use acs_user::get here?
    set user_email [db_string email_from_user_id {
        select email
        from parties
        where party_id = (select user_id
                          from users
                          where username = :username
                          )
    }]
        
    # Send email
    ns_sendmail $email $system_owner $subject $body
}

ad_proc -private auth::password::get_email_error_msg { errmsg } {
    Reusable message used when email sending fails.

    @author Peter Marklund
} {
    return "[_ acs-subsite.Error_sending_mail]
<blockquote>
  <pre>
    $errmsg
  </pre>
</blockquote>
"
}

ad_proc -private auth::password::CanChangePassword {
    {-authority_id ""}    
} {
    Can users change password for a given authority.
 
    @param authority_id The ID of the authority that we are inquiring about. Defaults to local
   
    @author Peter Marklund
} {
    if { [empty_string_p $authority_id] } {
        set authority_id [auth::authority::local]
    }

    # TODO:
    # Implement parameters

    return [acs_sc::invoke \
                -contract "auth_password" \
                -impl [auth::authority::get_element -authority_id $authority_id -element "auth_impl_name"] \
                -operation CanChangePassword \
                -call_args [list [list]]]
}

ad_proc -private auth::password::CanRetrievePassword {
    {-authority_id ""}    
} {
    Can users retrieve password for a given authority.

    @param authority_id The ID of the authority that we are inquiring about. Defaults to local

    @author Peter Marklund
} {
    if { [empty_string_p $authority_id] } {
        set authority_id [auth::authority::local]
    }

    # TODO:
    # Implement parameters

    return [acs_sc::invoke \
                -contract "auth_password" \
                -impl [auth::authority::get_element -authority_id $authority_id -element "auth_impl_name"] \
                -operation CanRetrievePassword \
                -call_args [list [list]]]
}

ad_proc -private auth::password::CanResetPassword {
    {-authority_id ""}    
} {
    Can users reset password for a given authority.

    @param authority_id The ID of the authority that we are inquiring about. Defaults to local

    @author Peter Marklund
} {
    if { [empty_string_p $authority_id] } {
        set authority_id [auth::authority::local]
    }

    # TODO:
    # Implement parameters

    return [acs_sc::invoke \
                -contract "auth_password" \
                -impl [auth::authority::get_element -authority_id $authority_id -element "auth_impl_name"] \
                -operation CanResetPassword \
                -call_args [list [list]]]
}

ad_proc -private auth::password::ChangePassword {
    {-username:required}
    {-old_password:required}
    {-new_password:required}
    {-authority_id ""}    
} {
    Change the password of a user.

    @param username
    @param old_password
    @param new_password
    @param authority_id The ID of the authority the user belongs to. Defaults to local

    @author Peter Marklund
} {
    if { [empty_string_p $authority_id] } {
        set authority_id [auth::authority::local]
    }

    # TODO:
    # Implement parameters

    return [acs_sc::invoke \
                -contract "auth_password" \
                -impl [auth::authority::get_element -authority_id $authority_id -element "auth_impl_name"] \
                -operation ChangePassword \
                -call_args [list $username \
                                 $old_password \
                                 $new_password \
                                 [list]]]
}

ad_proc -private auth::password::RetrievePassword {
    {-username:required}
    {-authority_id ""}    
} {
    Retrieve the password of a user.

    @param username
    @param authority_id The ID of the authority the user belongs to. Defaults to local

    @author Peter Marklund
} {
    if { [empty_string_p $authority_id] } {
        set authority_id [auth::authority::local]
    }

    # TODO:
    # Implement parameters

    return [acs_sc::invoke \
                -contract "auth_password" \
                -impl [auth::authority::get_element -authority_id $authority_id -element "auth_impl_name"] \
                -operation RetrievePassword \
                -call_args [list $username \
                                 [list]]]
}

ad_proc -private auth::password::ResetPassword {
    {-username:required}
    {-authority_id ""}    
} {
    Reset the password of a user.

    @param username
    @param authority_id The ID of the authority the user belongs to. Defaults to local

    @author Peter Marklund
} {
    if { [empty_string_p $authority_id] } {
        set authority_id [auth::authority::local]
    }

    # TODO:
    # Implement parameters

    return [acs_sc::invoke \
                -contract "auth_password" \
                -impl [auth::authority::get_element -authority_id $authority_id -element "auth_impl_name"] \
                -operation ResetPassword \
                -call_args [list $username \
                                 [list]]]
}
