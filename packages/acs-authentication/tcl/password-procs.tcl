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
        from   auth_authorities aa,
               users u
        where  aa.authority_id = u.authority_id
        and    u.user_id = :user_id
    }

    # Interpolate any username variable in URL
    regsub -all "{username}" $change_pwd_url $username change_pwd_url
    
    # Default to the OpenACS change password URL
    if { $change_pwd_url eq "" } {
        set change_pwd_url [export_vars -base "[subsite::get_element -element url]user/password-update" { user_id }]
    } 

    return $change_pwd_url
}

ad_proc -public auth::password::can_change_p {
    {-user_id:required}
} {
    Returns whether we can change the password for the given user.
    This depends on the user's authority and the configuration of that authority. 
    
    @param user_id The ID of the user whose password you want to change.

    @return 1 if the user can change password, 0 otherwise.
} {
    set authority_id [acs_user::get_element -user_id $user_id -element authority_id]

    set result_p 0
    with_catch errmsg { 
        set result_p [auth::password::CanChangePassword -authority_id $authority_id]
    } {
        ns_log Error "Error invoking CanChangePassword operation for authority_id $authority_id:\n$::errorInfo"
    }
    return $result_p
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

       <li> password_status: "ok", "no_account", "not_supported", "old_password_bad",
       "new_password_bad", "change_error", "failed_to_connect" </li>

       <li> password_message: A human-readable description of what
       went wrong. </li>

   </ul>
} {
    acs_user::get -user_id $user_id -array user

    with_catch errmsg {
        array set result [auth::password::ChangePassword \
                              -authority_id $user(authority_id) \
                              -username $user(username) \
                              -new_password $new_password \
			      -old_password $old_password ]

        # We do this so that if there aren't even a password_status in the array, that gets caught below
        set dummy $result(password_status)
    } {
        set result(password_status) failed_to_connect
        set result(password_message) $errmsg
        ns_log Error "Error invoking password management driver for authority_id = $user(authority_id):\n$::errorInfo"
    }
    
    # Check the result code and provide canned responses
    switch $result(password_status) {
        ok {
            # Invalidate existing login tokens sitting on random other browsers out there
            set connection_user_id [ad_conn user_id]

            sec_change_user_auth_token $user_id

            # Refresh the current user's cookies, so he doesn't get logged out, 
            # if this user was logged in before changing password
            if { [ad_conn isconnected] && $user_id == $connection_user_id } {
                auth::issue_login -account_status [ad_conn account_status] -user_id $user_id
            }
        } 
        no_account - not_supported - old_password_bad - new_password_bad - change_error - failed_to_connect {
            if { ![info exists result(password_message)] || $result(password_message) eq "" } {
                array set default_message {
                    no_account {Unknown username}
                    not_supported {This operation is not supported}
                    old_password_bad {Current password incorrect}
                    new_password_bad {New password not accepted}
                    change_error {Error changing password}
                    failed_to_connect {Error communicating with authentication server}
                }
                set result(password_message) $default_message($result(password_status))
            }
        }
        default {
            set result(password_status) "failed_to_connect"
            set result(password_message) "Illegal code returned from password management driver"
            ns_log Error "Error invoking password management driver for authority_id = $user(authority_id): Illegal return code from driver: $result(password_status)"
        }
    }

    return [array get result]
}

ad_proc -public auth::password::recover_password {
    {-authority_id ""}
    {-username ""}
    {-email ""}
} { 
    Handles forgotten passwords.  Attempts to retrieve a password; if not possibe, 
    attempts to reset a password.  If it succeeds, it emails the user.  For all 
    outcomes, it returns a message to be displayed.

    @param authority_id The ID of the authority that the user is trying to log into.
    @param username     The username that the user's trying to log in with.
    @param email        Email can be supplied instead of authority_id and username.

    @return Array list with the following entries:

    <ul>
        <li> password_status: ok, no_support, failed_to_connect
        <li> password_message: Human-readable message to be relayed to the user. May contain HTML.
    </ul>
} {
    if { $username eq "" } {
        if { $email eq "" } {
            set result(password_status) "failed_to_connect"
            if { [auth::UseEmailForLoginP] } {
                set result(password_message) "Email required"
            } else {
                set result(password_message) "Username required"
            }
            return [array get result]
        }
        set user_id [party::get_by_email -email $email]
        if { $user_id eq "" } {
            set result(password_status) "failed_to_connect"
            set result(password_message) "Unknown email"
            return [array get result]
        }
        acs_user::get -user_id $user_id -array user
        set authority_id $user(authority_id)
        set username $user(username)
    } else {
        # Default to local authority
        if { $authority_id eq "" } {
            set authority_id [auth::authority::local]
        }
    }

    set forgotten_url [auth::password::get_forgotten_url \
                           -remote_only \
                           -authority_id $authority_id \
                           -username $username]

    if { $forgotten_url ne "" } {
        ad_returnredirect -allow_complete_url $forgotten_url
        ad_script_abort
    }

    if { [auth::password::can_retrieve_p -authority_id $authority_id] } {
        array set result [auth::password::retrieve \
                              -authority_id $authority_id \
                              -username $username]
    } elseif { [auth::password::can_reset_p -authority_id $authority_id] } {
        array set result [auth::password::reset \
                              -authority_id $authority_id \
                              -username $username]
    } else {
        # Can't reset or retrieve - we give up
        set result(password_status) "not_supported"
        set result(password_message) [_ acs-subsite.sorry_forgotten_pwd]
    }

    return [array get result]
}

ad_proc -public auth::password::get_forgotten_url {
    {-authority_id ""}
    {-username ""}
    {-email ""}
    {-remote_only:boolean}
} { 
    Returns the URL to redirect to for forgotten passwords. 
        
    @param authority_id The ID of the authority that the user is trying to log into.
    @param username The username that the user's trying to log in with.
    @param remote_only If provided, only return any remote URL (not on this server).

    @return A URL that can be linked to when the user has forgotten his/her password, 
            or the empty string if none can be found.
} {
    if { $username ne "" } {
        set local_url [export_vars -no_empty -base "[subsite::get_element -element url]register/recover-password" { authority_id username }]
    } else {
        set local_url [export_vars -no_empty -base "[subsite::get_element -element url]register/recover-password" { email }]
    }
    set forgotten_pwd_url {}

    if { $username ne "" } {
        if { $authority_id eq "" } {
            set authority_id [auth::authority::local]
        }
    } else {
        set user_id [party::get_by_email -email $email]
        if { $user_id ne "" } {
            acs_user::get -user_id $user_id -array user
            set authority_id $user(authority_id)
            set username $user(username)
        }
    }

    if { $username ne "" } {
        # We have the username or email
        

        set forgotten_pwd_url [auth::authority::get_element -authority_id $authority_id -element forgotten_pwd_url]

        if { $forgotten_pwd_url ne "" } {
            regsub -all "{username}" $forgotten_pwd_url $username forgotten_pwd_url
        } elseif { !$remote_only_p } {
            if { [auth::password::can_retrieve_p -authority_id $authority_id] || [auth::password::can_reset_p -authority_id $authority_id] } {
                set forgotten_pwd_url $local_url
            }
        }
    } else {
        # We don't have the username
        if { !$remote_only_p } {
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
    set result_p 0
    with_catch errmsg { 
        set result_p [auth::password::CanRetrievePassword \
                    -authority_id $authority_id]
    } {
        ns_log Error "Error invoking CanRetrievePassword operation for authority_id $authority_id:\n$::errorInfo"
        return 0
    }
    return $result_p
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
    with_catch errmsg {
        array set result [auth::password::RetrievePassword \
                              -authority_id $authority_id \
                              -username $username]
        
        # We do this so that if there aren't even a password_status in the array, that gets caught below
        set dummy $result(password_status)
    } {
        set result(password_status) failed_to_connect
        set result(password_message) "Error invoking the password management driver."
        ns_log Error "Error invoking password management driver for authority_id = $authority_id: $::errorInfo"
    }
    
    # Check the result code and provide canned responses
    switch $result(password_status) {
        ok {
            if { [info exists result(password)] && $result(password) ne "" } {
                # We have retrieved or reset a forgotten password that we should email to the user
                with_catch errmsg {
                    auth::password::email_password \
                        -authority_id $authority_id \
                        -username $username \
                        -password $result(password) \
                        -subject_msg_key "acs-subsite.email_subject_Forgotten_password" \
                        -body_msg_key "acs-subsite.email_body_Forgotten_password" 
                } {
                    # We could not inform the user of his email - we failed
                    set result(password_status) "failed_to_connect"
                    set result(password_message) [_ acs-subsite.Error_sending_mail]
                    ns_log Error "We had an error sending out email with new password to username $username, authority $authority_id:\n$::errorInfo"
                }
            } 
            if { ![info exists result(password_message)] || $result(password_message) eq "" } {
                set result(password_message) [_ acs-subsite.Check_Your_Inbox]
            }
        } 
        no_account - not_supported - retrieve_error - failed_to_connect {
            if { ![info exists result(password_message)] || $result(password_message) eq "" } {
                array set default_message {
                    no_account {Unknown username}
                    not_supported {This operation is not supported}
                    retrieve_error {Error retrieving password}
                    failed_to_connect {Error communicating with authentication server}
                }
                set result(password_message) $default_message($result(password_status))
            }
        }
        default {
            set result(password_status) "failed_to_connect"
            set result(password_message) "Illegal error code returned from password management driver"
        }
    }

    return [array get result]
}

ad_proc -public auth::password::can_reset_p {
    {-authority_id:required}
} {
    Returns whether the given authority can reset forgotten passwords. 
    
    @param authority_id The ID of the authority that the user is trying to log into.

    @return 1 if the authority allows resetting passwords, 0 otherwise.
} {
    set result_p 0
    with_catch errmsg { 
        set result_p [auth::password::CanResetPassword \
                    -authority_id $authority_id]
    } {
        ns_log Error "Error invoking CanResetPassword operation for authority_id $authority_id:\n$::errorInfo"
    }
    return $result_p
}

ad_proc -public auth::password::reset {
    {-admin:boolean}
    {-authority_id:required}
    {-username:required}
} {
    Reset the user's password, which means setting it to a new
    randomly generated password and inform the user of that new
    password.

    @param admin             Specify this flag if this call represents an admin changing a user's password.

    @param authority_id      The authority of the user

    @param username          The username of the user

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
    with_catch errmsg {
        array set result [auth::password::ResetPassword \
                              -authority_id $authority_id \
                              -username $username]
        
        # We do this so that if there aren't even a password_status in the array, that gets caught below
        set dummy $result(password_status)
    } {
        set result(password_status) failed_to_connect
        set result(password_message) "Error invoking the password management driver."
        ns_log Error "Error invoking password management driver for authority_id = $authority_id: $::errorInfo"
    }
    
    # Check the result code and provide canned responses
    switch $result(password_status) {
        ok {
            if { [info exists result(password)] && $result(password) ne ""
                 && (!$admin_p || [parameter::get \
                                       -parameter EmailChangedPasswordP \
                                       -package_id [ad_conn subsite_id] \
                                       -default 1])
             } {
                # We have retrieved or reset a forgotten password that we should email to the user
                with_catch errmsg {
                    auth::password::email_password \
                        -authority_id $authority_id \
                        -username $username \
                        -password $result(password) \
                        -subject_msg_key "acs-subsite.email_subject_Forgotten_password" \
                        -body_msg_key "acs-subsite.email_body_Forgotten_password" 
                } {
                    # We could not inform the user of his email - we failed
                    set result(password_status) "failed_to_connect"
                    set result(password_message) [_ acs-subsite.Error_sending_mail]
                    ns_log Error "We had an error sending out email with new password to username $username, authority $authority_id:\n$::errorInfo"
                }
            }
            if { ![info exists result(password_message)] || $result(password_message) eq "" } {
                set result(password_message) [_ acs-subsite.Check_Your_Inbox]
            }
        } 
        no_account - not_supported - retrieve_error - failed_to_connect {
            if { (![info exists result(password_message)] || $result(password_message) eq "") } {
                array set default_message {
                    no_account {Unknown username}
                    not_supported {This operation is not supported}
                    reset_error {Error resetting password}
                    failed_to_connect {Error communicating with authentication server}
                }
                set result(password_message) $default_message($result(password_status))
            }
        }
        default {
            set result(password_status) "failed_to_connect"
            set result(password_message) "Illegal error code returned from password management driver"
        }
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
    {-authority_id:required}
    {-password:required}
    {-subject_msg_key "acs-subsite.email_subject_Forgotten_password"}
    {-body_msg_key "acs-subsite.email_body_Forgotten_password"}
    {-from ""}
} {
    Send an email to the user with given username and authority with the new password.

    @param from             The email's from address. Can be in email@foo.com <Your Name> format.
                            Defaults to ad_system_owner.
    
    @param subject_msg_key  The message key you wish to use for the email subject.

    @param body_msg_key     The message key you wish to use for the email body.

    @return Does not return anything. Any errors caused by acs_mail_lite::send are propagated

    @author Peter Marklund
} {
    set user_id [acs_user::get_by_username -authority_id $authority_id -username $username]
    acs_user::get -user_id $user_id -array user

    # Set up variables for use in message key
    set reset_password_url [export_vars -base "[ad_url]/user/password-update" {user_id {old_password $password}}]
    set forgotten_password_url [auth::password::get_forgotten_url \
                                    -authority_id $authority_id \
                                    -username $user(username) \
                                    -email $user(email)]
    set subsite_info [security::get_register_subsite]
    if {[dict get $subsite_info url] ne "/"} {
        set forgotten_password_url [dict get $subsite_info url]$forgotten_password_url
    }
    set forgotten_password_url [security::get_qualified_url $forgotten_password_url]

    set system_owner [ad_system_owner]
    set system_name [ad_system_name]
    set system_url [ad_url]
    if { [auth::UseEmailForLoginP] } {
        set account_id_label [_ acs-subsite.Email]
        set account_id $user(email)
    } else {
        set account_id_label [_ acs-subsite.Username]
        set account_id $user(username)
    }
    # Hm, all this crummy code, just to justify the colons in the email body
    set password_label [_ acs-subsite.Password]
    if { [string length $password_label] > [string length $account_id_label] } {
        set length [string length $password_label]
    } else {
        set length [string length $account_id_label]
    }
    set account_id_label [string range "$account_id_label[string repeat " " $length]" 0 [expr {$length-1}]]
    set password_label [string range "$password_label[string repeat " " $length]" 0 [expr {$length-1}]]

    set first_names $user(first_names)
    set last_name $user(last_name)

    if { [ad_conn untrusted_user_id] != 0 } {
        acs_user::get -user_id [ad_conn untrusted_user_id] -array admin_user
        set admin_first_names $admin_user(first_names)
        set admin_last_name $admin_user(last_name)
    } else {
        set admin_first_names {}
        set admin_last_name {}
    }
        
    set subject [_ $subject_msg_key]
    set body [_ $body_msg_key]
        
    if { $from eq "" } {
          set from [ad_system_owner]
      }

    # Send email
    acs_mail_lite::send -send_immediately \
        -to_addr $user(email) \
        -from_addr $system_owner \
        -subject $subject \
        -body $body
}

ad_proc -private auth::password::CanChangePassword {
    {-authority_id:required}
} {
    Invoke the CanChangePassword operation on the given authority. 
    Returns 0 if the authority does not have a password management driver.
 
    @param authority_id The ID of the authority that we are inquiring about.
   
    @author Peter Marklund
} {
    set impl_id [auth::authority::get_element -authority_id $authority_id -element "pwd_impl_id"]

    if { $impl_id eq "" } {
        return 0
    }

    set parameters [auth::driver::get_parameter_values \
                        -authority_id $authority_id \
                        -impl_id $impl_id]

    return [acs_sc::invoke \
                -error \
                -contract "auth_password" \
                -impl_id $impl_id \
                -operation CanChangePassword \
                -call_args [list $parameters]]
}

ad_proc -private auth::password::CanRetrievePassword {
    {-authority_id:required}
} {
    Invoke the CanRetrievePassword operation on the given authority. 
    Returns 0 if the authority does not have a password management driver.

    @param authority_id The ID of the authority that we are inquiring about. 

    @author Peter Marklund
} {
    set impl_id [auth::authority::get_element -authority_id $authority_id -element "pwd_impl_id"]

    if { $impl_id eq "" } {
        return 0
    }

    set parameters [auth::driver::get_parameter_values \
                        -authority_id $authority_id \
                        -impl_id $impl_id]

    return [acs_sc::invoke \
                -error \
                -contract "auth_password" \
                -impl_id $impl_id \
                -operation CanRetrievePassword \
                -call_args [list $parameters]]
}

ad_proc -private auth::password::CanResetPassword {
    {-authority_id:required}
} {
    Invoke the CanResetPassword operation on the given authority. 
    Returns 0 if the authority does not have a password management driver.

    @param authority_id The ID of the authority that we are inquiring about.

    @author Peter Marklund
} {
    set impl_id [auth::authority::get_element -authority_id $authority_id -element "pwd_impl_id"]

    if { $impl_id eq "" } {
        return 0
    }

    set parameters [auth::driver::get_parameter_values \
                        -authority_id $authority_id \
                        -impl_id $impl_id]

    return [acs_sc::invoke \
                -error \
                -contract "auth_password" \
                -impl_id $impl_id \
                -operation CanResetPassword \
                -call_args [list $parameters]]
}

ad_proc -private auth::password::ChangePassword {
    {-username:required}
    {-old_password ""}
    {-new_password:required}
    {-authority_id:required}
} {
    Invoke the ChangePassword operation on the given authority. 
    Throws an error if the authority does not have a password management driver.

    @param username
    @param old_password
    @param new_password
    @param authority_id The ID of the authority the user belongs to.

    @author Peter Marklund
} {
    set impl_id [auth::authority::get_element -authority_id $authority_id -element "pwd_impl_id"]
    
    if { $impl_id eq "" } {
        set authority_pretty_name [auth::authority::get_element -authority_id $authority_id -element "pretty_name"]
        error "The authority '$authority_pretty_name' doesn't support password management"
    }

    set parameters [auth::driver::get_parameter_values \
                        -authority_id $authority_id \
                        -impl_id $impl_id]

    return [acs_sc::invoke \
                -error \
                -contract "auth_password" \
                -impl_id $impl_id \
                -operation ChangePassword \
                -call_args [list $username \
                                 $new_password \
                                 $old_password \
                                 $parameters \
			         $authority_id]]
}

ad_proc -private auth::password::RetrievePassword {
    {-username:required}
    {-authority_id:required}
} {
    Invoke the RetrievePassword operation on the given authority. 
    Throws an error if the authority does not have a password management driver.

    @param username
    @param authority_id The ID of the authority the user belongs to.

    @author Peter Marklund
} {
    set impl_id [auth::authority::get_element -authority_id $authority_id -element "pwd_impl_id"]

    if { $impl_id eq "" } {
        set authority_pretty_name [auth::authority::get_element -authority_id $authority_id -element "pretty_name"]
        error "The authority '$authority_pretty_name' doesn't support password management"
    }

    set parameters [auth::driver::get_parameter_values \
                        -authority_id $authority_id \
                        -impl_id $impl_id]

    return [acs_sc::invoke \
                -error \
                -contract "auth_password" \
                -impl_id $impl_id \
                -operation RetrievePassword \
                -call_args [list $username \
                                 $parameters]]
}

ad_proc -private auth::password::ResetPassword {
    {-username:required}
    {-authority_id ""}    
} {
    Invoke the ResetPassword operation on the given authority. 
    Throws an error if the authority does not have a password management driver.

    @param username
    @param authority_id The ID of the authority the user belongs to. 

    @author Peter Marklund
} {
    set impl_id [auth::authority::get_element -authority_id $authority_id -element "pwd_impl_id"]

    if { $impl_id eq "" } {
        set authority_pretty_name [auth::authority::get_element -authority_id $authority_id -element "pretty_name"]
        error "The authority '$authority_pretty_name' doesn't support password management"
    }

    set parameters [auth::driver::get_parameter_values \
                        -authority_id $authority_id \
                        -impl_id $impl_id]

    return [acs_sc::invoke \
                -error \
                -contract "auth_password" \
                -impl_id $impl_id \
                -operation ResetPassword \
                -call_args [list $username \
				$parameters \
			        $authority_id]]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
