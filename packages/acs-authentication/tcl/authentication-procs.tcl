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

ad_proc -public auth::register_user {
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

    @param authority_id The id of the authority to create the user in. Defaults to
                        the authority with lowest sort_order that has register_p set to true.
} {
    set authorities_list [list]
    
    # Always register the user locally
    lappend authorities_list [auth::authority::local]

    # Default authority_id if none was provided
    if { [empty_string_p $authority_id] } {
        # Pick the first authority that can create users
        set authority_id [db_string first_registering_authority {
            select authority_id
            from auth_authorities
            where register_p = 't'
            and sort_order = (select max(sort_order)
                              from auth_authorities
                              where register_p = 't'
                             )
        } -default ""]

        if { [empty_string_p $authority_id] } {
            error "No authority_id provided and could not find an authority that can create users"
        }    

        lappend authorities_list $authority_id
    }    

    # Register the user both with the local authority and the external one
    db_transaction {
        foreach authority_id $authorities_list {
            auth::registration::Register \
                -authority_id $authority_id \
                -username $user_name \
                -password $password \
                -first_names $first_names \
                -last_name $last_name \
                -email $email \
                -url $url \
                -secret_question $secret_question \
                -secret_answer $secret_answer
        }
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
    {-authority_id:required}
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
