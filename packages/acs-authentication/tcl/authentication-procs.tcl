ad_library {
    Tcl API for authentication, account management, and account registration.

    @author Lars Pind (lars@collaobraid.biz)
    @creation-date 2003-05-13
    @cvs-id $Id$
}

namespace eval auth {}
namespace eval auth::authentication {}
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
    set user_id [ad_conn user_id]
    if { $user_id != 0 } {
	# user is in fact logged in, return user_id
	return $user_id
    }

    # The -return switch causes the URL to return to the current page
    ad_returnredirect [ad_get_login_url -return]
    ad_script_abort
}

ad_proc -public auth::authenticate {
    {-authority_id ""}
    {-username:required}
    {-password:required}
    {-persistent:boolean}
    {-no_cookie:boolean}
} {
    Try to authenticate and login the user forever by validating the username/password combination, 
    and return authentication and account status codes.    
    
    @param authority_id The ID of the authority to ask to verify the user. Defaults to local authority.
    @param username Authority specific username of the user.
    @param passowrd The password as the user entered it.
    @param persistent Set this if you want a permanent login cookie
    @param no_cookie Set this if you don't want to issue a login cookie
    
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

    with_catch errmsg {
        array set auth_info [auth::authentication::Authenticate \
                                 -username $username \
                                 -authority_id $authority_id \
                                 -password $password]

        # We do this so that if there aren't even the auth_status and account_status that need be
        # in the array, that gets caught below
        if { [string equal $auth_info(auth_status) "ok"] } {
            set dummy $auth_info(account_status)
        }
    } {
        set auth_info(auth_status) failed_to_connect
        set auth_info(auth_message) $errmsg
        global errorInfo
        ns_log Error "Error invoking authentication driver for authority_id = $authority_id: $errorInfo"
    }

    # Returns:
    #   auth_info(auth_status) 
    #   auth_info(auth_message) 
    #   auth_info(account_status) 
    #   auth_info(account_message) 

    # Verify auth_info/auth_message return codes
    switch $auth_info(auth_status) {
        ok { 
            # Continue below
        }
        no_account -
        bad_password -
        auth_error -
        failed_to_connect {
            if { ![exists_and_not_null auth_info(auth_message)] } {
                array set default_auth_message {
                    no_account {Unknown username}
                    bad_password {Bad password}
                    auth_error {Invalid username/password}
                    failed_to_connect {Error communicating with authentication server}
                }
                set auth_info(auth_message) $default_auth_message($auth_info(auth_status))
            }
            return [array get auth_info]
        }
        default {
            set auth_info(auth_status) "failed_to_connect"
            set auth_info(auth_message) "Illegal error code returned from authentication driver"
            return [array get auth_info]
        }
    }

    # Verify remote account_info/account_message return codes
    switch $auth_info(account_status) {
        ok { 
            # Continue below
            if { ![info exists auth_info(account_message)] } {
                set auth_info(account_message) {}
            }
        }
        closed {
            if { ![exists_and_not_null auth_info(account_message)] } {
                set auth_info(account_message) "This account is not available at this time"
            }
        }
        default {
            set auth_info(account_status) "closed"
            set auth_info(account_message) "Illegal error code returned from authentication driver"
        }
    }

    # Save the remote account information for later
    set remote_account_status $auth_info(account_status)
    set remote_account_message $auth_info(account_message)

    # Clear out remote account_status and account_message
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

    # Verify local account_info/account_message return codes
    switch $auth_info(account_status) {
        ok { 
            # Continue below
            if { ![info exists auth_info(account_message)] } {
                set auth_info(account_message) {}
            }
        }
        closed {
            if { ![exists_and_not_null auth_info(account_message)] } {
                set auth_info(account_message) "This account is not available at this time"
            }
        }
        default {
            set auth_info(account_status) "closed"
            set auth_info(account_message) "Illegal error code returned from authentication driver"
        }
    }
    
    # If the remote account was closed, the whole account is closed, regardless of local account status
    if { [string equal $remote_account_status "closed"] } {
        set auth_info(account_status) closed
    }

    if { [exists_and_not_null remote_account_message] } {
        if { [exists_and_not_null auth_info(account_message)] } {
            # Concatenate local and remote account messages
            set auth_info(account_message) "<p>[auth::authority::get_element -authority_id $authority_id -element pretty_name]: $remote_account_message </p> <p>[ad_system_name]: $auth_info(account_message)</p>"
        } else {
            set auth_info(account_message) $remote_account_message
        }
    }
        
    # Issue login cookie if login was successful
    if { [string equal $auth_info(auth_status) "ok"] && [string equal $auth_info(account_status) "ok"] && !$no_cookie_p } {
        auth::issue_login -user_id $auth_info(user_id) -persistent=$persistent_p
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

ad_proc -private auth::get_register_authority {
} {
    Get the ID of the authority in which accounts get created.
} {
    # HACK while waiting for real account creation
    return [auth::authority::local]
}

ad_proc -public auth::create_user {
    {-verify_password_confirm:boolean}
    {-user_id ""}
    {-username ""}
    {-email ""}
    {-first_names ""}
    {-last_name ""}
    {-email ""}
    {-password ""}
    {-password_confirm ""}
    {-url ""}
    {-secret_question ""}
    {-secret_answer ""}
    {-email_verified_p ""} 
    {-member_state "approved"}
} {
    Create a user, and return creation status and account status.
    
    @param email_verified_p Whether the local account considers the email to be verified or not.

    @param member_state     Whether the local account has been approved.

    @param verify_password_confirm
                            Set this flag if you want the proc to verify that password and password_confirm match for you.
                            
    @return Array list containing the following entries:

    <ul>
      <li> creation_status:  ok, data_error, reg_error, failed_to_connect. Says whether user creation succeeded.
      <li> creation_message: Information about the problem, to be relayed to the user. If creation_status is not ok, then either 
                             creation_message or element_messages is guaranteed to be non-empty, and both are 
                             guaranteed to be in the array list.  May contain HTML.
      <li> element_messages: list of (element_name, message, element_name, message, ...) of 
                             errors on the individual elements (username, password, first_names, ...), 
                             to be relayed on to the user. If creation_status is not ok, then either 
                             creation_message or element_messages is guaranteed to be non-empty, and both are 
                             guaranteed to be in the array list. Cannot contain HTML.
      <li> account_status:   ok, closed. Only set if creation_status was ok, this says whether the newly created account 
                             is ready for use or not. For example, we may require approval, in which case the account 
                             would be created but closed.
      <li> account_message:  A human-readable explanation of why the account was closed. May include HTML, and thus shouldn't
                             be quoted. Guaranteed to be non-empty if account_status is not ok.
    </ul>
} {
    set authority_id [auth::get_register_authority]

    # This holds element error messages
    array set element_messages [list]

    #####
    #
    # Check for missing required fields
    #
    #####

    # We do this first, so that double-click protection works correctly

    set missing_elements_p 0
    array set reg_elms [auth::get_registration_elements]
    foreach elm $reg_elms(required) {
        if { [empty_string_p [set $elm]] } {
            set element_messages($elm) "Required"
            set missing_elements_p 1
        }
    }
    if { $verify_password_confirm_p } {
        if { ![empty_string_p "$password$password_confirm"] && ![string equal $password $password_confirm] } {
            set element_messages(password) "Passwords don't match"
            set missing_elements_p 1
        }
    }
    if { $missing_elements_p } {
        return [list \
                    creation_status data_error \
                    creation_message "Missing required fields" \
                    element_messages [array get element_messages] \
                   ]
    }
    


    #####
    #
    # Create local account
    #
    #####

    array set creation_info [auth::create_local_account \
                                 -user_id $user_id \
                                 -authority_id $authority_id \
                                 -username $username \
                                 -first_names $first_names \
                                 -last_name $last_name \
                                 -email $email \
                                 -url $url \
                                 -member_state $member_state \
                                 -email_verified_p $email_verified_p]

    # Returns: 
    #   creation_info(creation_status)
    #   creation_info(creation_message)  
    #   creation_info(element_messages)  
    #   creation_info(account_status)
    #   creation_info(account_message)  
    #   creation_info(user_id)

    # We don't do any fancy error checking here, because create_local_account is not a service contract
    # so we control it 100%

    if { ![string equal $creation_info(creation_status) "ok"] } {
        # Local account creation error
        return [array get creation_info]
    }

    # Save the local account information for later
    set local_account_status $creation_info(account_status)
    set local_account_message $creation_info(account_message)

    # Clear out remote creation_info array for reuse
    array set creation_info {
        creation_status {}
        creation_message {}  
        element_messages {}  
        account_status {}
        account_message {}  
    }


    #####
    #
    # Create remote account
    #
    #####

    with_catch errmsg {
        array set creation_info [auth::registration::Register \
                                     -authority_id $authority_id \
                                     -username $username \
                                     -password $password \
                                     -first_names $first_names \
                                     -last_name $last_name \
                                     -email $email \
                                     -url $url \
                                     -secret_question $secret_question \
                                     -secret_answer $secret_answer]
    } {
        set auth_info(auth_status) failed_to_connect
        set auth_info(auth_message) $errmsg
        global errorInfo
        ns_log Error "Error invoking account registratino driver for authority_id = $authority_id: $errorInfo"
    }
    
    
    # Returns:
    #   creation_info(creation_status) 
    #   creation_info(creation_message) 
    #   creation_info(element_messages) 
    #   creation_info(account_status) 
    #   creation_info(account_message) 

    # Verify creation_info/creation_message return codes
    array set default_creation_message {
        data_error {Problem with user data}
        reg_error {Unknown registration error}
        failed_to_connect {Error communicating with account server}
    }

    switch $creation_info(creation_status) {
        ok { 
            # Continue below
        }
        data_error -
        reg_error -
        failed_to_connect {
            if { ![exists_and_not_null creation_info(creation_message)] } {
                set creation_info(creation_message) $default_creation_message($creation_info(creation_status))
            }
            if { ![info exists creation_info(element_messages)] } {
                set creation_info(element_messages) {}
            }
            return [array get creation_info]
        }
        default {
            set creation_info(creation_status) "failed_to_connect"
            set creation_info(creation_message) "Illegal error code returned from account creation driver"
            return [array get creation_info]
        }
    }

    # Verify remote account_info/account_message return codes
    switch $creation_info(account_status) {
        ok { 
            # Continue below
            set creation_info(account_message) {}
        }
        closed {
            if { ![exists_and_not_null creation_info(account_message)] } {
                set creation_info(account_message) "This account is not available at this time"
            }
        }
        default {
            set creation_info(account_status) "closed"
            set creation_info(account_message) "Illegal error code returned from creationentication driver"
        }
    }

    

    #####
    # 
    # Clean up, concat account messages, issue login cookie
    #
    #####
    
    # If the local account was closed, the whole account is closed, regardless of remote account status
    if { [string equal $local_account_status "closed"] } {
        set creation_info(account_status) closed
    }

    if { [exists_and_not_null local_account_message] } {
        if { [exists_and_not_null creation_info(account_message)] } {
            # Concatenate local and remote account messages
            set creation_info(account_message) "<p>[auth::authority::get_element -authority_id $authority_id -element pretty_name]: $creation_info(account_message)</p> <p>[ad_system_name]: $local_account_message</p>"
        } else {
            set creation_info(account_message) $local_account_message
        }
    }
        
    # Issue login cookie if login was successful
    if { [string equal $creation_info(creation_status) "ok"] && [string equal $creation_info(account_status) "ok"] && [ad_conn user_id] == 0 } {
        auth::issue_login -user_id $creation_info(user_id)
    }
    
    return [array get creation_info]
}

ad_proc -public auth::get_registration_elements {
} {
    Get the list of required/optional elements for user registration.
    
    @return Array-list with two entries, both being a subset of 
            (username, password, first_names, last_name, email, url, secret_question, secret_answer).
            
    <ul>
      <li> required: a list of required elements
      <li> optional: a list of optional elements
    </ul>
            
} {
    set authority_id [auth::get_register_authority]

    array set element_info [auth::registration::GetElements -authority_id $authority_id]
    
    if { ![info exists element_info(required)] } {
        set element_info(required) {}
    }
    if { ![info exists element_info(optional)] } {
        set element_info(optional) {}
    }

    # Handle required elements for local account
    foreach elm { first_names last_name email } {
        # Add to required
        if { [lsearch $element_info(required) $elm] == -1 } {
            lappend element_info(required) $elm
        }
            
        # Remove from optional
        set index [lsearch $element_info(optional) $elm]
        if { $index != -1 } {
            set element_info(optional) [lreplace $element_info(optional) $index $index]
        }
    }

    return [array get element_info]
}

ad_proc -public auth::get_registration_form_elements {
    {-authority_id ""}
} {
    Returns a list of elements to be included in the -form chunk of an ad_form form.
    All possible elements will always be present, but those that shouldn't be displayed 
    will be hidden and have a hard-coded empty string value.
} {
    array set data_types {
        username text
        email text
        first_names text
        last_name text
        url text
        password text
        password_confirm text
        secret_question text
        secret_answer text
    }

    array set widgets {
        username text 
        email text
        first_names text
        last_name text
        url text
        password password
        password_confirm password
        secret_question text
        secret_answer text
    }
    
    array set labels [list \
                          username [_ acs-subsite.Username] \
                          email [_ acs-subsite.Your_email_address] \
                          first_names [_ acs-subsite.First_names] \
                          last_name [_ acs-subsite.Last_name] \
                          url [_ acs-subsite.lt_Personal_Home_Page_UR] \
                          password [_ acs-subsite.Password] \
                          password_confirm [_ acs-subsite.lt_Password_Confirmation] \
                          secret_question [_ acs-subsite.Question] \
                          secret_answer [_ acs-subsite.Answer]]

    array set html {
        username {size 30}
        email {size 30}
        first_names {size 20}
        last_name {size 25}
        url {size 50 value "http://"}
        password {size 20}
        password_confirm {size 20}
        secret_question {size 30}
        secret_answer {size 30}
    }
    
    array set element_info [auth::get_registration_elements]

    if { [lsearch $element_info(required) password] != -1 } {
        lappend element_info(required) password_confirm
    }
    if { [lsearch $element_info(optional) password] != -1 } {
        lappend element_info(optional) password_confirm
    }
    
    # required_p will have 1 if required, 0 if optional, and unset if not in the form
    array set required_p [list]
    foreach element $element_info(required) {
        set required_p($element) 1
    }
    foreach element $element_info(optional) {
        set required_p($element) 0
    }

    set form_elements [list]
    foreach element { username email first_names last_name password password_confirm url secret_question secret_answer } {
        if { [info exists required_p($element)] } {
            set form_element [list]

            # The header with name, datatype, and widget
            set form_element_header "${element}:$data_types($element)($widgets($element))"

            if { !$required_p($element) } {
                append form_element_header ",optional"
            }
            lappend form_element $form_element_header

            # The label
            lappend form_element [list label $labels($element)]

            # HTML
            lappend form_element [list html $html($element)]

            # The form element is finished - add it to the list
            lappend form_elements $form_element
        } else {
            lappend form_elements "${element}:text(hidden),optional [list value {}]"
        }
    }

    return $form_elements
}

ad_proc -public auth::create_local_account {
    {-user_id ""}
    {-authority_id:required}
    {-username ""}
    {-first_names ""}
    {-last_name ""}
    {-email ""}
    {-url ""}
    {-secret_question ""}
    {-secret_answer ""}
    {-member_state "approved"}
    {-email_verified_p ""}
} {
    Create the local account for a user.

    @return Array list containing the following entries:

    <ul>
      <li> creation_status:  ok, data_error, reg_error, failed_to_connect. Says whether user creation succeeded.
      <li> creation_message: Information about the problem, to be relayed to the user. If creation_status is not ok, then either 
                             creation_message or element_messages is guaranteed to be non-empty, and both are 
                             guaranteed to be in the array list.  May contain HTML.
      <li> element_messages: list of (element_name, message, element_name, message, ...) of 
                             errors on the individual elements (username, password, first_names, ...), 
                             to be relayed on to the user. If creation_status is not ok, then either 
                             creation_message or element_messages is guaranteed to be non-empty, and both are 
                             guaranteed to be in the array list. Cannot contain HTML.
      <li> account_status:   ok, closed. Only set if creation_status was ok, this says whether the newly created account 
                             is ready for use or not. For example, we may require approval, in which case the account 
                             would be created but closed.
      <li> account_message:  A human-readable explanation of why the account was closed. May include HTML, and thus shouldn't
                             be quoted. Guaranteed to be non-empty if account_status is not ok.
    </ul>

    All entries are guaranteed to always be set, but may be empty.
} {
    array set result {
        creation_status reg_error
        creation_message {}
        element_messages {}
        account_status ok
        account_message {}
        user_id {}
    }

    # PHASE II: This needs to be controlled by a parameter
    if { [empty_string_p $username] } {
        set username $email
    }

    # Validate data
    set user_vars { authority_id username first_names last_name email url secret_question secret_answer }
    foreach varname $user_vars {
        if { [info exists $varname] } {
            set user_info($varname) [set $varname]
        }
    }

    auth::validate_user_info \
        -user_array user_info \
        -message_array element_messages

    # Handle validation errors
    if { [llength [array names element_messages]] > 0 } {
        return [list \
                    creation_status "data_error" \
                    creation_message {} \
                    element_messages [array get element_messages] \
                   ]
    }

    # Suck user info variables back out, they may have been modified by the validate helper proc
    foreach varname $user_vars {
        if { [info exists user_info($varname)] } {
            set $varname $user_info($varname)
        }
    }


    # Admin approval
    if { [parameter::get -parameter RegistrationRequiresApprovalP -default 0] } {
        set member_state "needs approval"
        set result(account_status) "closed"
        set result(account_message) [_ acs-subsite.lt_Your_registration_is_]
    } else {
        set member_state "approved"
    }

    if { [empty_string_p $email_verified_p] } {
        if { [parameter::get -parameter RegistrationRequiresEmailVerificationP -default 0] } {
            set email_verified_p "f"
        } else {
            set email_verified_p "t"
        }
    }
    
    set error_p 0
    with_catch errmsg {
        # We create the user without a password
        # If it's a local account, that'll get set later
        set user_id [ad_user_new \
                         $email \
                         $first_names \
                         $last_name \
                         {} \
                         $secret_question \
                         $secret_answer \
                         $url \
                         $email_verified_p \
                         $member_state \
                         $user_id \
                         $username \
                         $authority_id]
    } {
        set error_p 1
    } 

    if { $error_p || $user_id == 0 } {
        set result(creation_status) "failed_to_connect"
        set result(creation_message) "We experienced an error while trying to register an account for you."
        global errorInfo
        ns_log Error "Error creating local account.\n$errorInfo"
        return [array get result]
    }

    set result(user_id) $user_id
    
    # Creation succeeded
    set result(creation_status) "ok"

    if { [parameter::get -parameter RegistrationRequiresEmailVerificationP -default 0] } {
        set result(account_status) "closed"
        set result(account_message) "<p>[_ acs-subsite.lt_Registration_informat_1]</p><p>[_ acs-subsite.lt_Please_read_and_follo]</p>"

        with_catch errmsg {
            auth::send_email_verification_email -user_id $user_id
        } {
            global errorInfo
            ns_log Error "auth::get_local_account: Error sending out email verification email to email $email:\n$errorInfo"
            set auth_info(account_message) "We got an error sending out the email for email verification"
        }
    }

    return [array get result]
}


ad_proc -public auth::update_local_account {
    {-authority_id:required}
    {-username:required}
    {-first_names ""}
    {-last_name ""}
    {-email ""}
    {-url ""}
    {-secret_question ""}
    {-secret_answer ""}
    {-member_state "approved"}
    {-email_verified_p ""}
} {
    Update the local account for a user.

    @return Array list containing the following entries:

    <ul>
      <li> update_status:    ok, data_error, update_error, failed_to_connect. Says whether user update succeeded.
      <li> update_message:   Information about the problem, to be relayed to the user. If update_status is not ok, then either 
                             update_message or element_messages is guaranteed to be non-empty, and both are 
                             guaranteed to be in the array list.  May contain HTML.
      <li> element_messages: list of (element_name, message, element_name, message, ...) of 
                             errors on the individual elements (username, password, first_names, ...), 
                             to be relayed on to the user. If update_status is not ok, then either 
                             udpate_message or element_messages is guaranteed to be non-empty, and both are 
                             guaranteed to be in the array list. Cannot contain HTML.
    </ul>

    All entries are guaranteed to always be set, but may be empty.
} {
    array set result {
        update_status update_error
        update_message {}
        element_messages {}
        user_id {}
    }

    # Validate data

    # Updating: Find the existing account    
    set user_vars { authority_id username first_names last_name email url secret_question secret_answer }
    foreach varname $user_vars {
        if { [info exists $varname] } {
            set user_info($varname) [set $varname]
        }
    }

    auth::validate_user_info \
        -update \
        -user_array user_info \
        -message_array element_messages

    # Handle validation errors
    if { [llength [array names element_messages]] > 0 } {
        return [list \
                    update_status "data_error" \
                    update_message {} \
                    element_messages [array get element_messages] \
                   ]
    }

    # Suck user info variables back out, they may have been modified by the validate helper proc
    foreach varname $user_vars {
        if { [info exists user_info($varname)] } {
            set $varname $user_info($varname)
        }
    }
    
    # We get user_id from validate_user_info above, and set it in the result array so our caller can get it
    set user_id $user_info(user_id)
    set result(user_id) $user_id

    set error_p 0
    with_catch errmsg {

        db_transaction {
            # Update persons: first_names, last_name
            person::update \
                -person_id $user_id \
                -first_names $first_names \
                -last_name $last_name
            
            # Update parties: email, url
            if { [empty_string_p $email] } {
                set success_p 0
                set message "Email is required"
            }
            party::update \
                -party_id $user_id \
                -email $email \
                -url $url
            
            # Update users: email_verified_p
            if { ![empty_string_p $email_verified_p] } {
                acs_user::update \
                    -user_id $user_id \
                    -email_verified_p $email_verified_p
            }
                
            # TODO: Portrait
        }
    } {
        set error_p 1
    } 

    if { $error_p } {
        set result(update_status) "failed_to_connect"
        set result(update_message) "We experienced an error while trying to update the account information."
        global errorInfo
        ns_log Error "Error updating local account.\n$errorInfo"
        return [array get result]
    }

    # Update succeeded
    set result(update_status) "ok"

    return [array get result]
}


ad_proc -public auth::delete_local_account {
    {-authority_id:required}
    {-username:required}
} {
    Delete the local account for a user.

    @return Array list containing the following entries:

    <ul>
      <li> delete_status:  ok, delete_error, failed_to_connect. Says whether user deletion succeeded.
      <li> delete_message: Information about the problem, to be relayed to the user. If delete_status is not ok, then 
                           delete_message is guaranteed to be non-empty. May contain HTML.
    </ul>

    All entries are guaranteed to always be set, but may be empty.
} {
    array set result {
        delete_status ok
        delete_message {}
        user_id {}
    }

    set user_id [acs_user::get_by_username \
                     -authority_id $authority_id \
                     -username $username]
    
    if { [empty_string_p $user_id] } {
        set result(delete_status) "delete_error"
        set result(delete_message) "No user found with this username"
        return [array get result]
    }
    
    # Mark the account banned
    acs_user::ban -user_id $user_id

    set result(user_id) $user_id

    return [array get result]
}


ad_proc -private auth::validate_user_info {
    {-update:boolean}
    {-user_array:required}
    {-message_array:required}
} { 
    Validates user info and returns errors, if any.
    
    @param update        Set this flag if you're updating an existing record, meaning we shouldn't check for duplicates.

    @param user_array    Name of an array in the caller's namespace which contains the user info 
                         (authority_id, username, email, first_names, last_name, url, secret_question, secret_answer). 

    @param message_array Name of an array where you want the validation errors stored, keyed by element name.
} {
    upvar 1 $user_array user
    upvar 1 $message_array element_messages

    foreach elm { authority_id username first_names last_name email } {
        if { ![exists_and_not_null user($elm)] } {
            set element_messages($elm) "Required"
        }
    }

    if { $update_p && [exists_and_not_null user(authority_id)] && [exists_and_not_null user(username)] } {
        set user(user_id) [acs_user::get_by_username \
                               -authority_id $user(authority_id) \
                               -username $user(username)]
        
        if { [empty_string_p $user(user_id)] } {
            set element_messages(username) "No user with username '$user(username)' found for authority [auth::authority::get_element -authority_id $user(authority_id) -element pretty_name]"
        }
    }

    if { [exists_and_not_null user(first_names)] && [string first "<" $user(first_names)] != -1 } {
        set element_messages(first_names) [_ acs-subsite.lt_You_cant_have_a_lt_in]
    }

    if { [exists_and_not_null user(last_name)] && [string first "<" $user(last_name)] != -1 } {
        set element_messages(last_name) [_ acs-subsite.lt_You_cant_have_a_lt_in_1]
    }

    if { [exists_and_not_null user(email)] && ![util_email_valid_p $user(email)] } {
        set element_messages(email) "This is not a valid email address"
    } else {
        set user(email) [string tolower $user(email)]
    }
    
    if { ![exists_and_not_null user(url)] || ([info exists user(url)] && [string equal $user(url) "http://"]) } {
        # The user left the default hint for the url
        set user(url) {}
    } elseif { ![util_url_valid_p $user(url)] } {
        set valid_url_example "http://openacs.org/"
        set element_messages(url) [_ acs-subsite.lt_Your_URL_doesnt_have_]
    }

    if { [exists_and_not_null user(email)] } {
        # Check that email is unique
        set email $user(email)
        set email_party_id [party::get_by_email -email $user(email)]

        if { ![empty_string_p $email_party_id] && (!$update_p || $email_party_id != $user(user_id)) } {
            # We found a user with this email, and either we're not updating, or it's not the same user_id as the one we're updating
            
            if { ![string equal [acs_object_type $email_party_id] "user"] } {
                set element_messages(email) "We already have a group with this email"
            } else {
                acs_user::get \
                    -user_id $email_party_id \
                    -array email_user
                
                switch $email_user(member_state) {
                    banned {
                        # A user with this email does exist, but he's banned, so we can 'steal' his email address
                        # by setting it to something dummy
                        party::update \
                            -party_id $email_party_id \
                            -email "dummy-email-$email_party_id"
                    }
                    default { 
                        set element_messages(email) "We already have a user with this email."
                    }
                } 
            }
        }
    }
        
    if { [exists_and_not_null user(username)] } {
        # Check that username is unique
        set username_user_id [acs_user::get_by_username -authority_id $user(authority_id) -username $user(username)]
        
        if { ![empty_string_p $username_user_id] && (!$update_p || $username_user_id != $user(user_id)) } {
            # We found a user with this username, and either we're not updating, or it's not the same user_id as the one we're updating

            set username_member_state [acs_user::get_element -user_id $username_user_id -element member_state] 
            switch $username_member_state {
                banned {
                    # A user with this username does exist, but he's banned, so we can 'steal' his username
                    # by setting it to something dummy
                    acs_user::update \
                        -user_id $username_user_id \
                        -username "dummy-username-$username_user_id"
                }
                default { 
                    set element_messages(username) "We already have a user with this username."
                }
            }
        }
    }
}

ad_proc -public auth::set_email_verified {
    {-user_id:required}
} {
    Update an OpenACS record with the fact that the email address on
    record was verified.
} {
    acs_user::update \
        -user_id $user_id \
        -email_verified_p "t"
}

ad_proc -private auth::can_admin_system_without_authority_p {
    {-authority_id:required}
} {
    Before disabling or deleting an authority we need to check
    that there is at least one site-wide admin in a different
    authority that can administer the system. This proc returns
    1 if there is such an admin and 0 otherwise.

    @author Peter Marklund
} {
    set number_of_admins_left [db_string count_admins_left {
        select count(*)
        from cc_users u,
             acs_object_party_privilege_map pm,
             acs_magic_objects mo
        where authority_id <> :authority_id
        and pm.privilege = 'admin'
        and pm.object_id = mo.object_id
        and mo.name = 'security_context_root'
        and pm.party_id = u.user_id
        and u.member_state = 'approved'
    }]

    return [ad_decode $number_of_admins_left "0" "0" "1"]
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

    set notification_address [parameter::get -parameter NewRegistrationEmailAddress -default [ad_system_owner]]

    # system_name is used in some of the I18N messages
    set system_name [ad_system_name]    
    switch $member_state {
        approved {
            if { $email_verified_p == "f" } {
                set auth_info(account_message) "<p>[_ acs-subsite.lt_Registration_informat]</p><p>[_ acs-subsite.lt_Please_read_and_follo]</p>"
                
                with_catch errmsg {
                    auth::send_email_verification_email -user_id $user_id
                } {
                    global errorInfo
                    ns_log Error "auth::get_local_account: Error sending out email verification email to email $email:\n$errorInfo"
                    set auth_info(account_message) "We got an error sending out the email for email verification"
                }
                
            } else {
                set auth_info(account_status) "ok"
            }
        }
        banned { 
            set auth_info(account_message) [_ acs-subsite.lt_Sorry_but_it_seems_th]
        }
        deleted {  
            set auth_info(account_message) \
                "[_ acs-subsite.Welcome_Back_1] <a href=\"restore-user?[export_vars { user_id }]\">[_ acs-subsite.to_site_link_1]</a>."
        }
        rejected - needs_approval {
            set auth_info(account_message) \
                "<p>[_ acs-subsite.lt_registration_request_submitted]</p><p>[_ acs-subsite.Thank_you]</p>"
        }
        default {
            set auth_info(account_message) \
                "There was a problem authenticating the account: $user_id. Most likely, the database contains users with no member_state."
            ns_log Error "Problem with registration state machine: user_id $user_id has member_state '$member_state'"
        }
    }
    set auth_info(user_id) $user_id

   return [array get auth_info]    
}

ad_proc -private auth::get_user_secret_token {
    -user_id:required
} {
    Get a secret token for the user. Can be used for email verification purposes. 
} {
    return [db_string select_secret_token {}]
}

ad_proc -private auth::send_email_verification_email {
    -user_id:required
} {
    Sends out an email to the user that lets them verify their email.
    Throws an error if we couldn't send out the email.
} {
    # These are used in the messages below
    set token [auth::get_user_secret_token -user_id $user_id]
    acs_user::get -user_id $user_id -array user
    set confirmation_url [export_vars -base "[ad_url]/register/email-confirm" { token user_id }]
    set system_name [ad_system_name]    

    ns_sendmail \
        $user(email) \
        [parameter::get -parameter NewRegistrationEmailAddress -default [ad_system_owner]] \
        [_ acs-subsite.lt_Welcome_to_system_nam] \
        [_ acs-subsite.lt_To_confirm_your_regis]
}


#####
#
# auth::authentication
#
#####

ad_proc -private auth::authentication::Authenticate {
    {-authority_id:required}
    {-username:required}
    {-password:required}
} {
    Invoke the Authenticate service contract operation for the given authority.

    @param authority_id The ID of the authority to ask to verify the user. 
    @param username Username of the user.
    @param passowrd The password as the user entered it.    
} {
    set impl_id [auth::authority::get_element -authority_id $authority_id -element "auth_impl_id"]

    if { [empty_string_p $impl_id] } {
        # No implementation of authentication
        set authority_pretty_name [auth::authority::get_element -authority_id $authority_id -element "pretty_name"]
        error "The authority '$authority_pretty_name' doesn't support authentication"
    }

    set parameters [auth::driver::get_parameter_values \
                        -authority_id $authority_id \
                        -impl_id $impl_id]

    return [acs_sc::invoke \
                -error \
                -impl_id $impl_id \
                -operation Authenticate \
                -call_args [list $username $password $parameters]]
}

#####
#
# auth::registration
#
#####

ad_proc -private auth::registration::Register {
    {-authority_id:required}
    {-username ""}
    {-password ""}
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
    set impl_id [auth::authority::get_element -authority_id $authority_id -element "register_impl_id"]

    if { [empty_string_p $impl_id] } {
        # No implementation of authentication
        set authority_pretty_name [auth::authority::get_element -authority_id $authority_id -element "pretty_name"]
        error "The authority '$authority_pretty_name' doesn't support account registration"
    }

    set parameters [auth::driver::get_parameter_values \
                        -authority_id $authority_id \
                        -impl_id $impl_id]

    return [acs_sc::invoke \
                -error \
                -impl_id $impl_id \
                -operation Register \
                -call_args [list $parameters \
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
    {-authority_id:required}
} {
    @author Peter Marklund
} {
    set impl_id [auth::authority::get_element -authority_id $authority_id -element "register_impl_id"]

    if { [empty_string_p $impl_id] } {
        # No implementation of authentication
        set authority_pretty_name [auth::authority::get_element -authority_id $authority_id -element "pretty_name"]
        error "The authority '$authority_pretty_name' doesn't support account registration"
    }

    set parameters [auth::driver::get_parameter_values \
                        -authority_id $authority_id \
                        -impl_id $impl_id]

    return [acs_sc::invoke \
                -error \
                -impl_id $impl_id \
                -operation GetElements \
                -call_args [list $parameters]]
}


