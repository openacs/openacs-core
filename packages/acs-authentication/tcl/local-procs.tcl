ad_library {
    Procs for local authentication.

    @author Lars Pind (lars@collaobraid.biz)
    @creation-date 2003-05-13
    @cvs-id $Id$
}

namespace eval auth {}
namespace eval auth::local {}
namespace eval auth::local::authentication {}
namespace eval auth::local::password {}
namespace eval auth::local::registration {}
namespace eval auth::local::user_info {}
namespace eval auth::local::search {}

#####
#
# auth::local
#
#####

ad_proc -private auth::local::install {} {
    Register local service contract implementations, 
    and update the local authority with live information.
} {
    db_transaction {
        # Register the local service contract implementations
        set row(auth_impl_id) [auth::local::authentication::register_impl]
        set row(pwd_impl_id) [auth::local::password::register_impl]
        set row(register_impl_id) [auth::local::registration::register_impl]
	set row(user_info_impl_id) [auth::local::user_info::register_impl]

        # Set the authority pretty-name to be the system name
        set row(pretty_name) [ad_system_name]
        
        auth::authority::edit \
            -authority_id [auth::authority::local] \
            -array row
    }
}

ad_proc -private auth::local::uninstall {} {
    Unregister the local service contract implementation, and update the 
    local authority to reflect that.
} {
    db_transaction {
        # Update the local authority to reflect the loss of the implementations
        set row(auth_impl_id) {}
        set row(pwd_impl_id) {}
        set row(register_impl_id) {}

        auth::authority::edit \
            -authority_id [auth::authority::local] \
            -array row

        # Unregister the implementations
        auth::local::authentication::unregister_impl
        auth::local::password::unregister_impl
        auth::local::registration::unregister_impl
    }
}




#####
#
# auth::local::authentication
#
#####
#
# The 'auth_authentication' service contract implementation
#

ad_proc -private auth::local::authentication::register_impl {} {
    Register the 'local' implementation of the 'auth_authentication' service contract.
    
    @return impl_id of the newly created implementation.
} {
    set spec {
        contract_name "auth_authentication"
        owner "acs-authentication"
        name "local"
        pretty_name "Local"
        aliases {
            MergeUser auth::local::authentication::MergeUser
            Authenticate auth::local::authentication::Authenticate
            GetParameters auth::local::authentication::GetParameters
        }
    }

    return [acs_sc::impl::new_from_spec -spec $spec]
}

ad_proc -private auth::local::authentication::unregister_impl {} {
    Unregister the 'local' implementation of the 'auth_authentication' service contract.
} {
    acs_sc::impl::delete -contract_name "auth_authentication" -impl_name "local"
}

ad_proc -private auth::local::authentication::MergeUser {
    from_user_id
    to_user_id
    {authority_id ""}
} {
    Merge Implementation of local authentication. This will
    merge the names, emails, usernames, permissions, etc
    of the two users to merge.
} {
    ns_log Notice "Starting auth::local::authentication::MergeUser"
    db_transaction {
	ns_log Notice "  Merging user portraits"

	ns_log notice "  Merging username, email and basic info in general"

	set new_username "merged_$from_user_id"
	append new_username "_$to_user_id"
	
	# Shall we keep the domain for email?
	# Actually, the username 'merged_xxx_yyy'
	# won't be an email, so we will keep it without
	# domain 
	set new_email $new_username
	    
	set rel_id [db_string getrelid {}]  
	membership_rel::change_state -rel_id $rel_id -state "merged"
	
	acs_user::update -user_id $from_user_id -username "$new_username" -screen_name "$new_username"
	party::update -party_id $from_user_id -email "$new_email" 
	
    }
    ns_log notice "Finishing auth::local::authentication::MergeUser"
}


ad_proc -private auth::local::authentication::Authenticate {
    username
    password
    {parameters {}}
    {authority_id {}}
} {
    Implements the Authenticate operation of the auth_authentication 
    service contract for the local account implementation.
} {
    array set auth_info [list]

    if {$authority_id eq ""} {
	set authority_id [auth::authority::local]
    }

    set user_id [acs_user::get_by_username -authority_id $authority_id -username $username]
    if { $user_id eq "" } {
        set result(auth_status) "no_account"
        return [array get result]
    }

    if { [ad_check_password $user_id $password] } {
        set auth_info(auth_status) "ok"
    } else {
        set auth_info(auth_status) "bad_password"
        set auth_info(auth_message) [_ acs-authentication.Invalid_username_or_password]
        return [array get auth_info]
    }

    # We set 'external' account status to 'ok', because the 
    # local account status will be checked anyways by the framework
    set auth_info(account_status) ok

    return [array get auth_info]
}

ad_proc -private auth::local::authentication::GetParameters {} {
    Implements the GetParameters operation of the auth_authentication 
    service contract for the local account implementation.
} {
    # No parameters
    return [list]
}


#####
#
# auth::local::password
#
#####
#
# The 'auth_password' service contract implementation
#

ad_proc -private auth::local::password::register_impl {} {
    Register the 'local' implementation of the 'auth_password' service contract.
    
    @return impl_id of the newly created implementation.
} {
    set spec {
        contract_name "auth_password"
        owner "acs-authentication"
        name "local"
        pretty_name "Local"
        aliases {
            CanChangePassword auth::local::password::CanChangePassword
            ChangePassword auth::local::password::ChangePassword
            CanRetrievePassword auth::local::password::CanRetrievePassword
            RetrievePassword auth::local::password::RetrievePassword
            CanResetPassword auth::local::password::CanResetPassword
            ResetPassword auth::local::password::ResetPassword
            GetParameters auth::local::password::GetParameters
        }
    }
    return [acs_sc::impl::new_from_spec -spec $spec]
}

ad_proc -private auth::local::password::unregister_impl {} {
    Unregister the 'local' implementation of the 'auth_password' service contract.
} {
    acs_sc::impl::delete -contract_name "auth_password" -impl_name "local"
}


ad_proc -private auth::local::password::CanChangePassword {
    {parameters ""}
} {
    Implements the CanChangePassword operation of the auth_password 
    service contract for the local account implementation.
} {
    # Yeah, we can change your password
    return 1
}

ad_proc -private auth::local::password::CanRetrievePassword {
    {parameters ""}
} {
    Implements the CanRetrievePassword operation of the auth_password 
    service contract for the local account implementation.
} {
    # passwords are stored hashed, so we send the hash and let the user choose a new password
    return 1
}

ad_proc -private auth::local::password::CanResetPassword {
    {parameters ""}
} {
    Implements the CanResetPassword operation of the auth_password 
    service contract for the local account implementation.
} {
    # Yeah, we can reset for you.
    return 1
}

ad_proc -private auth::local::password::ChangePassword {
    username
    new_password
    {old_password ""}
    {parameters {}}
    {authority_id {}}
} {
    Implements the ChangePassword operation of the auth_password 
    service contract for the local account implementation.
} {
    array set result { 
        password_status {}
        password_message {} 
    }

    set user_id [acs_user::get_by_username -authority_id $authority_id -username $username]
    if { $user_id eq "" } {
        set result(password_status) "no_account"
        return [array get result]
    }

    if { $old_password ne "" } {
	if { ![ad_check_password $user_id $old_password] } {
	    set result(password_status) "old_password_bad"
	    return [array get result]
	}
    }

    if { [catch { ad_change_password $user_id $new_password } errmsg] } {
        set result(password_status) "change_error"
        ns_log Error "Error changing local password for username $username, user_id $user_id: \n$::errorInfo"
        return [array get result]
    }

    set result(password_status) "ok"

    if { [parameter::get -parameter EmailAccountOwnerOnPasswordChangeP -package_id [ad_acs_kernel_id] -default 1] } {
	with_catch errmsg {
	    acs_user::get -username $username -authority_id $authority_id -array user
	    
	    set system_name [ad_system_name]
	    set pvt_home_name [ad_pvt_home_name]
	    set password_update_link_text [_ acs-subsite.Change_my_Password]
	    
	    if { [auth::UseEmailForLoginP] } {
		set account_id_label [_ acs-subsite.Email]
		set account_id $user(email)
	    } else {
		set account_id_label [_ acs-subsite.Username]
		set account_id $user(username)
	    }
	    
	    set subject [_ acs-subsite.Password_changed_subject]
	    set body [_ acs-subsite.Password_changed_body]
	    
	    acs_mail_lite::send \
            -send_immediately \
            -to_addr $user(email) \
            -from_addr [ad_outgoing_sender] \
            -subject $subject \
            -body $body
	} {
            ns_log Error "Error sending out password changed notification to account owner with user_id $user(user_id), email $user(email): $errmsg\n$::errorInfo"
	}
    }
    
    return [array get result]
}

ad_proc -private auth::local::password::RetrievePassword {
    username
    parameters
} {
    Implements the RetrievePassword operation of the auth_password 
    service contract for the local account implementation.
} {
    set result(password_status) "ok"
    set result(password_message) [_ acs-subsite.Request_Change_Password_token_email]

    db_1row get_usr_id_and_password_hash {SELECT user_id, password as password_hash FROM users WHERE username = :username}

    set email [party::email -party_id $user_id]
    # TODO: This email message text should go in the recipient user language, english or every language supported
    set subject "[ad_system_name]: [_ acs-subsite.change_password_email_subject] $username"
    set body "[_ acs-subsite.change_password_email_body_0]\n\n[export_vars -base "[ad_url]/user/password-reset" {user_id password_hash}]\n\n[_ acs-subsite.change_password_email_body_1]"

    acs_mail_lite::send \
        -send_immediately \
        -to_addr $email \
        -from_addr [ad_outgoing_sender] \
        -subject $subject \
        -body $body

    return [array get result]
}

ad_proc -private auth::local::password::ResetPassword {
    username
    parameters
    {authority_id {}}
    {new_password {}}
} {
    Implements the ResetPassword operation of the auth_password 
    service contract for the local account implementation.
} {
    array set result { 
        password_status ok
        password_message {} 
    }

    set user_id [acs_user::get_by_username -authority_id $authority_id -username $username]
    if { $user_id eq "" } {
        set result(password_status) "no_account"
        return [array get result]
    }

    # Reset the password
    if { $new_password ne "" } {
	set password $new_password
    } else {
	set password [ad_generate_random_string]
    }

    ad_change_password $user_id $password

    # We return the new passowrd here and let the OpenACS framework send the email with the new password
    set result(password) $password
    return [array get result]
}

ad_proc -private auth::local::password::GetParameters {} {
    Implements the GetParameters operation of the auth_password
    service contract for the local account implementation.
} {
    # No parameters
    return [list]
}


#####
#
# auth::local::register
#



#####
#
# The 'auth_registration' service contract implementation
#

ad_proc -private auth::local::registration::register_impl {} {
    Register the 'local' implementation of the 'auth_registration' service contract.
    
    @return impl_id of the newly created implementation.
} {
    set spec {
        contract_name "auth_registration"
        owner "acs-authentication"
        name "local"
        pretty_name "Local"
        aliases {
            GetElements auth::local::registration::GetElements
            Register auth::local::registration::Register
            GetParameters auth::local::registration::GetParameters
        }
    }
    return [acs_sc::impl::new_from_spec -spec $spec]
}

ad_proc -private auth::local::registration::unregister_impl {} {
    Unregister the 'local' implementation of the 'auth_register' service contract.
} {
    acs_sc::impl::delete -contract_name "auth_registration" -impl_name "local"
}

ad_proc -private auth::local::registration::GetElements {
    {parameters ""}
} {
    Implements the GetElements operation of the auth_registration
    service contract for the local account implementation.
} {
    set result(required) {}
    if { ![auth::UseEmailForLoginP] } {
        set result(required) username 
    }

    lappend result(required) email first_names last_name
    set result(optional) { url }

    if { ![parameter::get -package_id [ad_conn subsite_id] -parameter RegistrationProvidesRandomPasswordP -default 0] } {
        lappend result(optional) password
    }

    if { [parameter::get -package_id [ad_acs_kernel_id] -parameter RequireQuestionForPasswordResetP -default 0] && 
         [parameter::get -package_id [ad_acs_kernel_id] -parameter UseCustomQuestionForPasswordReset -default 0] } {
        lappend result(required) secret_question secret_answer 
    }

    return [array get result]
}

ad_proc -private auth::local::registration::Register {
    parameters
    username
    authority_id
    first_names
    last_name
    screen_name
    email
    url
    password
    secret_question
    secret_answer
} {
    Implements the Register operation of the auth_registration
    service contract for the local account implementation.
} {
    array set result {
        creation_status "ok"
        creation_message {}
        element_messages {}
        account_status "ok"
        account_message {}
        generated_pwd_p 0
        password {}
    }

    # We don't create anything here, so creation always succeeds
    # And we don't check local account, either

    # LARS TODO: Move this out of the local driver and into the auth framework
    # Generate random password?
    set generated_pwd_p 0
    if { $password eq "" || [parameter::get -package_id [ad_conn subsite_id] -parameter RegistrationProvidesRandomPasswordP -default 0] } {
        set password [ad_generate_random_string]
        set generated_pwd_p 1
    }
    set result(generated_pwd_p) $generated_pwd_p
    set result(password) $password

    # Set user's password
    set user_id [acs_user::get_by_username -username $username]
    ad_change_password $user_id $password

    # Used in messages below
    set system_name [ad_system_name]
    set system_url [ad_url]

    # LARS TODO: Move this out of the local driver and into the auth framework
    # Send password confirmation email to user
    if { [set email_reg_confirm_p [parameter::get \
                                       -parameter EmailRegistrationConfirmationToUserP \
                                       -package_id [ad_conn subsite_id] -default 1]] != 0
     } {
	if { $generated_pwd_p
             || [parameter::get \
                     -parameter RegistrationProvidesRandomPasswordP \
                     -package_id [ad_conn subsite_id] -default 0]
             || $email_reg_confirm_p
         } {
	    with_catch errmsg {
		auth::password::email_password \
		    -username $username \
		    -authority_id $authority_id \
		    -password $password \
		    -from [parameter::get \
                               -parameter NewRegistrationEmailAddress \
                               -package_id [ad_conn subsite_id] \
                               -default [ad_system_owner]] \
		    -subject_msg_key "acs-subsite.email_subject_Registration_password" \
		    -body_msg_key "acs-subsite.email_body_Registration_password" 
	    } {
		# We don't fail hard here, just log an error
		ns_log Error "Error sending registration confirmation to $email.\n$::errorInfo"
	    }
	}
    }

    # LARS TODO: Move this out of the local driver and into the auth framework
    # Notify admin on new registration
    if { [parameter::get -parameter  NotifyAdminOfNewRegistrationsP -default 0] } {
        with_catch errmsg {
            set admin_email [parameter::get \
                                 -parameter NewRegistrationEmailAddress \
                                 -package_id [ad_conn subsite_id] \
                                 -default [ad_system_owner]]
            set admin_id [party::get_by_email -email $admin_email]
            if { $admin_id eq "" } {
                set admin_locale [lang::system::site_wide_locale]
            } else {
                set admin_locale [lang::user::locale -user_id $admin_id]
            }

            set system_url [ad_url]

            acs_mail_lite::send \
                -send_immediately \
                -to_addr $admin_email \
                -from_addr [ad_outgoing_sender] \
                -subject [lang::message::lookup $admin_locale acs-subsite.lt_New_registration_at_s] \
                -body [lang::message::lookup $admin_locale acs-subsite.lt_first_names_last_name]
        } {
            # We don't fail hard here, just log an error
            ns_log Error "Error sending admin notification to $admin_email.\n$::errorInfo"
        }
    }

    return [array get result]
}

ad_proc -private auth::local::registration::GetParameters {} {
    Implements the GetParameters operation of the auth_registration
    service contract for the local account implementation.
} {
    # No parameters
    return [list]
}

#####
#
# The 'auth_user_info' service contract implementation
#

ad_proc -private auth::local::user_info::register_impl {} {
    Register the 'local' implementation of the 'auth_user_info' service contract. 
    
    @return impl_id of the newly created implementation.
} {
    set spec {
        contract_name "auth_user_info"
        owner "acs-authentication"
        name "local"
        pretty_name "Local"
        aliases {
            GetUserInfo auth::local::user_info::GetUserInfo
            GetParameters auth::local::user_info::GetParameters
        }
    }
    return [acs_sc::impl::new_from_spec -spec $spec]
}

ad_proc -private auth::local::user_info::unregister_impl {} {
    Unregister the 'local' implementation of the 'auth_user_info' service contract.
} {
    acs_sc::impl::delete -contract_name "auth_user_info" -impl_name "local"
}

ad_proc -private auth::local::user_info::GetUserInfo {
    username
    {parameters ""}
} {
    Implements the GetUserInfo operation of the auth_user_info
    service contract for the local account implementation.
} {
    set user_id [acs_user::get_by_username -username $username]
    set result(info_status) [auth::get_local_account_status -user_id $user_id]
    set result(info_message) ""
    db_1row get_user_info {} -column_array user_info
    set result(user_info) [array get user_info]

    return [array get result]
}

ad_proc -private auth::local::user_info::GetParameters {} {
    Implements the GetParameters operation of the auth_user_info
    service contract for the local account implementation.
} {
    # No parameters
    return [list]
}

ad_proc -private auth::local::search::Search {
    search_text
    {parameters ""}
} {
    Implements the Search operation of the auth_search
    service contract for the local account implementation.
} {

    set results [list]
    db_foreach user_search {} {
	lappend results $user_id
    }

    return $results

}

ad_proc -private auth::local::search::GetParameters {} {
    Implements the GetParameters operation of the auth_search
    service contract for the local account implementation.
} {
    # No parameters
    return [list]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
