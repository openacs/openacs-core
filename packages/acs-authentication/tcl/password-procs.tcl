ad_library {
    Tcl API for password management.

    @author Lars Pind (lars@collaobraid.biz)
    @creation-date 2003-09-03
    @cvs-id $Id$
}


namespace eval auth::password {}


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

ad_proc -public auth::password::recover_password {
    {-authority_id:required}
    {-username:required}
} { 
    Handles forgotten passwords.  Attempts to retrieve a password; if not possibe, 
    attempts to reset a password.  If it succeeds, it emails the user.  For all 
    outcomes, it returns a message to be displayed.

    @param authority_id The ID of the authority that the user is trying to log into.
    @param username The username that the user's trying to log in with.

    @return Array list with the following entries:

    <ul>
        <li> password_status: ok, no_support, failed_to_connect
        <li> password_message: Human-readable message to be relayed to the user. May contain HTML.
    </ul>
} {

    set forgotten_url [auth::password::get_forgotten_url \
                           -remote_only \
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
    if { ![empty_string_p $username] } {
        # We have the username

        if { [empty_string_p $authority_id] } {
            set authority_id [auth::authority::local]
        }

        set forgotten_pwd_url [db_string select_forgotten_pwd_url {
            select forgotten_pwd_url
            from auth_authorities
            where authority_id = :authority_id
        }]

        if { ![empty_string_p $forgotten_pwd_url] } {
            regsub -all "{username}" $forgotten_pwd_url $username forgotten_pwd_url
        } else {
            if { ! $remote_only_p } {
                # If we can retrive or reset passwords we can use the local url
                # In remote mode we fail
                set can_retrieve_p [auth::password::can_retrieve_p -authority_id $authority_id]
                set can_reset_p [auth::password::can_reset_p -authority_id $authority_id]
                if { $can_retrieve_p || $can_reset_p } {
                    set forgotten_pwd_url [export_vars -base "[subsite::get_element -element url]register/recover-password" { authority_id username }]
                }
            }
        }
    } else {
        # We don't have the username

        if { $remote_only_p } {
            # Remote recovery requires username and authority so we fail
            set forgotten_pwd_url {}
        } else {            
            set forgotten_pwd_url "[subsite::get_element -element url]register/recover-password"
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
    ns_sendmail $user_email $system_owner $subject $body
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

    set impl_name [auth::authority::get_element -authority_id $authority_id -element "pwd_impl_name"]
    set impl_id [auth::authority::get_element -authority_id $authority_id -element "pwd_impl_id"]


    set parameters [auth::driver::get_parameter_values \
                        -authority_id $authority_id \
                        -impl_id $impl_id]

    return [acs_sc::invoke \
                -contract "auth_password" \
                -impl $impl_name \
                -operation CanChangePassword \
                -call_args [list $parameters]]
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

    set impl_name [auth::authority::get_element -authority_id $authority_id -element "pwd_impl_name"]
    set impl_id [auth::authority::get_element -authority_id $authority_id -element "pwd_impl_id"]


    set parameters [auth::driver::get_parameter_values \
                        -authority_id $authority_id \
                        -impl_id $impl_id]

    return [acs_sc::invoke \
                -contract "auth_password" \
                -impl $impl_name \
                -operation CanRetrievePassword \
                -call_args [list $parameters]]
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

    set impl_name [auth::authority::get_element -authority_id $authority_id -element "pwd_impl_name"]
    set impl_id [auth::authority::get_element -authority_id $authority_id -element "pwd_impl_id"]

    set parameters [auth::driver::get_parameter_values \
                        -authority_id $authority_id \
                        -impl_id $impl_id]

    return [acs_sc::invoke \
                -contract "auth_password" \
                -impl $impl_name \
                -operation CanResetPassword \
                -call_args [list $parameters]]
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

    set impl_name [auth::authority::get_element -authority_id $authority_id -element "pwd_impl_name"]
    set impl_id [auth::authority::get_element -authority_id $authority_id -element "pwd_impl_id"]

    set parameters [auth::driver::get_parameter_values \
                        -authority_id $authority_id \
                        -impl_id $impl_id]

    return [acs_sc::invoke \
                -contract "auth_password" \
                -impl $impl_name \
                -operation ChangePassword \
                -call_args [list $username \
                                 $old_password \
                                 $new_password \
                                 $parameters]]
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

    set impl_name [auth::authority::get_element -authority_id $authority_id -element "pwd_impl_name"]
    set impl_id [auth::authority::get_element -authority_id $authority_id -element "pwd_impl_id"]

    set parameters [auth::driver::get_parameter_values \
                        -authority_id $authority_id \
                        -impl_id $impl_id]

    return [acs_sc::invoke \
                -contract "auth_password" \
                -impl $impl_name \
                -operation RetrievePassword \
                -call_args [list $username \
                                 $parameters]]
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

    set impl_name [auth::authority::get_element -authority_id $authority_id -element "pwd_impl_name"]
    set impl_id [auth::authority::get_element -authority_id $authority_id -element "pwd_impl_id"]

    set parameters [auth::driver::get_parameter_values \
                        -authority_id $authority_id \
                        -impl_id $impl_id]

    return [acs_sc::invoke \
                -error \
                -contract "auth_password" \
                -impl $impl_name \
                -operation ResetPassword \
                -call_args [list $username \
                                 $parameters]]
}
