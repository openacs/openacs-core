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
        aliases {
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


ad_proc -private auth::local::authentication::Authenticate {
    username
    password
    {parameters {}}
} {
    Implements the GetParameters operation of the auth_authentication 
    service contract for the local account implementation.
} {
    array set auth_info [list]

    # TODO: username = email parameter ...

    set username [string tolower $username]
    
    set authority_id [auth::authority::local]

    set account_exists_p [db_0or1row select_user_info {
        select user_id
        from   cc_users
        where  username = :username
        and    authority_id = :authority_id
    }] 
    
    if { !$account_exists_p } {
        set auth_info(auth_status) "no_account"
        return [array get auth_info]
    }
    
    if { [ad_check_password $user_id $password] } {
        set auth_info(auth_status) "ok"
    } else {
        set auth_info(auth_status) "bad_password"
        return [array get auth_info]
    }

    # We set 'external' account status to 'ok', because the 
    # local account status will be checked anyways
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
        aliases {
            CanChangePassword auth::local::password::CanChangePassword
            ChangePassword auth::local::password::ChangePassword
            CanRetrievePassword auth::local::password::CanRetrievePassword
            RetrievePassword auth::local::password::RetrievePassword
            CanResetPassword auth::local::password::CanResetPassword
            ResetPassword auth::local::password::ResetPassword
        }
    }
    return [acs_sc::impl::new_from_spec -spec $spec]
}

ad_proc -private auth::local::password::unregister_impl {} {
    Unregister the 'local' implementation of the 'auth_password' service contract.
} {
    acs_sc::impl::delete -contract_name "auth_password" -impl_name "local"
}


ad_proc -private auth::local::password::CanChangePassword {} {
    Implements the CanChangePassword operation of the auth_password 
    service contract for the local account implementation.
} {
    # Yeah, we can change your password
    return 1
}

ad_proc -private auth::local::password::CanRetrievePassword {} {
    Implements the CanRetrievePassword operation of the auth_password 
    service contract for the local account implementation.
} {
    # Nope, passwords are stored hashed, so we can't retrieve it for you
    return 0
}

ad_proc -private auth::local::password::CanResetPassword {} {
    Implements the CanResetPassword operation of the auth_password 
    service contract for the local account implementation.
} {
    # Yeah, we can reset for you.
    return 1
}

ad_proc -private auth::local::password::ChangePassword {
    username
    old_password
    new_password
    {parameters {}}
} {
    Implements the ChangePassword operation of the auth_password 
    service contract for the local account implementation.
} {
    array set result { 
        successful_p 0
        message {} 
    }
    
    if { ![ad_check_password $user_id $old_password] } {
        set result(message) "Old password is incorrect."
        return [array get result]
    }
    if { [catch { ad_change_password $user_id $password_1 } errmsg] } {
        ns_log Warning "Error changing local password: $errmsg"
        set result(message) "We experienced an error changing your password."
        return [array get result]
    }

    set result(successful_p) 1

    return [array get result]
}

ad_proc -private auth::local::password::RetrievePassword {
    username
    parameters
} {
    Implements the RetrievePassword operation of the auth_password 
    service contract for the local account implementation.
} {
    set result(successful_p) 0
    set result(message) "Cannot retrieve your password."

    return [array get result]
}

ad_proc -private auth::local::password::ResetPassword {
    username
    parameters
} {
    Implements the ResetPassword operation of the auth_password 
    service contract for the local account implementation.
} {
    set result(successful_p) 0
    set result(message) {}

    # TODO: 
    # What about security question/answer? Who should ask for those?

    # Change the password
    set password [ad_generate_random_string]
    ad_change_password $user_id $password

    # We return the new passowrd here and let the OpenACS framework send the email with the new password
    set result(password) $password

    return [array get result]
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
    Implements the GetElements operation of the auth_register
    service contract for the local account implementation.
} {
    set result(required) { username email first_names last_name }
    set result(optional) { url }

    if { ![parameter::get -parameter RegistrationProvidesRandomPasswordP -default 0] } {
        lappend result(required) password
    }

    if { [parameter::get -parameter RequireQuestionForPasswordResetP -default 1] && 
         [parameter::get -parameter UseCustomQuestionForPasswordReset -default 1] } {
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
    email
    url
    password
    secret_question
    secret_answer
} {
    Implements the Register operation of the auth_register
    service contract for the local account implementation.
} {
    array set result {
        creation_status "reg_error"
        creation_message {}
        element_messages {}
        account_status "ok"
        account_message {}
    }

    # TODO: email = username
    # TODO: Add catch

    set user_id [ad_user_new \
                     $email \
                     $first_names \
                     $last_name \
                     $password \
                     $question \
                     $answer \
                     $url \
                     $email_verified_p \
                     $member_state \
                     "" \
                     $username \
                     $authority_id]

    if { !$user_id } {
        set result(creation_status) "fail"
        set result(creation_message) "We experienced an error while trying to register an account for you."
        return [array get result]
    }
    
    # Creation succeeded
    set result(creation_status) "ok"

    # TODO: validate data (see user-new-2.tcl)
    # TODO: double-click protection

    # Get whether they requre some sort of approval
    if { [parameter::get -parameter RegistrationRequiresApprovalP -default 0] } {
        set member_state "needs approval"
        set result(account_status) "closed"
        set result(account_message) [_ acs-subsite.lt_Your_registration_is_]
    } else {
        set member_state "approved"
    }

    set notification_address [parameter::get -parameter NewRegistrationEmailAddress -default [ad_system_owner]]

    if { [parameter::get -parameter RegistrationRequiresEmailVerificationP -default 0] } {
        set email_verified_p "f"
        set result(account_status) "closed"
        set result(account_message) "<p>[_ acs-subsite.lt_Registration_informat_1]</p><p>[_ acs-subsite.lt_Please_read_and_follo]</p>"

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
        } {
	    ns_returnerror "500" "$errmsg"
	    ns_log Warning "Error sending email verification email to $email. Error: $errmsg"
	}

    } else {
        set email_verified_p "t"
    }

    # Send password/confirmail email to user
    if { [parameter::get -parameter RegistrationProvidesRandomPasswordP -default 0] || \
             [parameter::get -parameter EmailRegistrationConfirmationToUserP -default 0] } {
	with_catch errmsg {
	    ns_sendmail \
                $email \
                $notification_address \
                "[_ acs-subsite.lt_Welcome_to_system_nam]" \
                "[_ acs-subsite.lt_Thank_you_for_visitin]"
	} {
	    ns_returnerror "500" "$errmsg"
	    ns_log Warning "Error sending registration confirmation to $email. Error: $errmsg"
	}
    }

    # Notify admin on new registration
    if {[ad_parameter NotifyAdminOfNewRegistrationsP "security" 0]} {
	with_catch errmsg {
            ns_sendmail \
                $notification_address \
                $email \
                "[_ acs-subsite.lt_New_registration_at_s]" \
                "[_ acs-subsite.lt_first_names_last_name]"
	} {
	    ns_returnerror "500" "$errmsg"
	    ns_log Warning "Error sending admin notification to $notification_address. Error: $errmsg"
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
