# /www/register/user-new-2.tcl

ad_page_contract {
    Enters a new user into the database.
    @cvs-id  $Id$
} {
    { email }
    { password }
    { password_confirmation }
    { first_names:notnull }
    { last_name:notnull }
    { question "" }
    { answer "" }
    { url }
    { user_id:integer,notnull }
    { return_url [ad_pvt_home] }
    { persistent_cookie_p 0 }
} -properties {
    title:onevalue
    email_verified_p:onevalue
    email:onevalue
    site_link:onevalue    
}

# xxx: Need an equivalent to ad_handle_spammers.

set exception_count 0
set exception_text ""

if {[info exists first_names] && [string first "<" $first_names] != -1} {
    incr exception_count
    append exception_text "<li> [_ acs-subsite.lt_You_cant_have_a_lt_in]"
}

if {[info exists last_name] && [string first "<" $last_name] != -1} {
    incr exception_count
    append exception_text "<li> [_ acs-subsite.lt_You_cant_have_a_lt_in_1]"
}

if { [info exists url] && [string compare $url "http://"] == 0 } {
    # the user left the default hint for the url
    set url ""
} elseif { ![util_url_valid_p $url] } {
    # there is a URL but it doesn't match our REGEXP
    incr exception_count
    set valid_url_example "http://photo.net/philg/"
    append exception_text "<li>[_ acs-subsite.lt_Your_URL_doesnt_have_]\n"
} elseif { [string compare $password $password_confirmation] } {
    incr exception_count
    append exception_text "<li>[_ acs-subsite.lt_The_passwords_youve_e]\n"
}

# We've checked everything.
# If we have an error, return error page, otherwise, do the insert

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    ad_script_abort
}

# Get whether they requre some sort of approval
if {[ad_parameter RegistrationRequiresApprovalP "security" 0]} {
    set member_state "needs approval"
} else {
    set member_state "approved"
}

if {[ad_parameter RegistrationRequiresEmailVerificationP "security" 0]} {
    set email_verified_p "f"
} else {
    set email_verified_p "t"
}


set double_click_p 0

if { [db_string user_exists "select count(*) from registered_users where user_id = :user_id"] } {
    set double_click_p 1
} else {
    set user_id [ad_user_new $email $first_names $last_name $password $question $answer $url $email_verified_p $member_state $user_id]
    if { !$user_id } {
	ad_return_error "[_ acs-subsite.User_Creation_Failed]" "[_ acs-subsite.lt_We_were_unable_to_cre]"
        ad_script_abort
    }

    # Carry over the user's locale preference
    lang::user::set_locale [lang::user::locale]
}

set script_abort 0
if { $member_state == "approved" && $email_verified_p == "t"} {
    # user is ready to go    
    if { [ad_check_password $user_id $password] } {
	# Log the user in.
	ad_user_login -forever=$persistent_cookie_p $user_id
    }

    ad_returnredirect $return_url
#   JCD: DO NOT return or ad_script_abort since we may need to fall through 
#   to notify admin of a new registration. Instead set a flag to abort at end...
    set script_abort 1
    
} elseif { $email_verified_p == "f" }  { 

    # this user won't be able to use the system until he has answered his email
    # so don't give an auth cookie, but instead tell him 
    # to read your email

    set title "[_ acs-subsite.lt_Please_read_your_emai]"

    ad_return_template
} elseif { $member_state == "needs approval" } {

    # this user won't be able to use the system until an admin has
    # approved him, so don't give an auth cookie, but instead tell him 
    # to wait

    set title "[_ acs-subsite.Awaiting_Approval]"
    set site_link [ad_site_home_link]

    ad_return_template
} 

set notification_address [ad_parameter NewRegistrationEmailAddress "security" [ad_system_owner]]
set errmsg {}

# Variables needed in various messages to the user below
set system_name [ad_system_name]
set system_url [ad_url]

if { !$double_click_p } {
    
    if { $email_verified_p == "f" } {
	
	set row_id [db_string user_new_2_rowid_for_email "select rowid from users where user_id = :user_id"]
	# the user has to come back and activate their account

	ns_sendmail $email $notification_address "Welcome to [ad_system_name]" "To confirm your registration, please go to [ad_parameter -package_id [ad_acs_kernel_id] SystemURL]/register/email-confirm?[export_url_vars row_id]"
	
    } elseif { [ad_parameter RegistrationProvidesRandomPasswordP "security" 0] ||  [ad_parameter EmailRegistrationConfirmationToUserP "security" 0] } {
	with_catch errmsg {
	    ns_sendmail $email $notification_address "[_ acs-subsite.lt_Thank_you_for_visitin]"
	} {
	    ns_returnerror "error" "$error"
	    ns_log Warning "Error sending registration confirmation to $email in user-new-2"
	}
    }

    if {[ad_parameter NotifyAdminOfNewRegistrationsP "security" 0]} {
        # we're supposed to notify the administrator when someone new registers
        ns_sendmail $notification_address $email "[_ acs-subsite.lt_New_registration_at_s]" "[_ acs-subsite.lt_first_names_last_name]
$errmsg
#>"
    }
}

if {$script_abort} {
    ad_script_abort
}
