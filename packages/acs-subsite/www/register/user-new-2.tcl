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
    append exception_text "<li> You can't have a &lt; in your first name because it will look like an HTML tag and confuse other users."
}

if {[info exists last_name] && [string first "<" $last_name] != -1} {
    incr exception_count
    append exception_text "<li> You can't have a &lt; in your last name because it will look like an HTML tag and confuse other users."
}

if { [info exists url] && [string compare $url "http://"] == 0 } {
    # the user left the default hint for the url
    set url ""
} elseif { ![util_url_valid_p $url] } {
    # there is a URL but it doesn't match our REGEXP
    incr exception_count
    append exception_text "<li>You URL doesn't have the correct form.  A valid URL would be something like \"http://photo.net/philg/\"."
}

if {[ad_parameter RegistrationProvidesRandomPasswordP security 0]} {
    set password [ad_generate_random_string]
} elseif { ![info exists password] || [empty_string_p $password] } {
    incr exception_count
    append exception_text "<li>You haven't provided a password.\n"
} elseif { [string compare $password $password_confirmation] } {
    incr exception_count
    append exception_text "<li>The passwords you've entered don't match.\n"
}

# We've checked everything.
# If we have an error, return error page, otherwise, do the insert

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
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
	ad_return_error "User Creation Failed" "We were unable to create your user record in the database."
    }
}

if { $member_state == "approved" && $email_verified_p == "t"} {
    # user is ready to go    
    if { [ad_check_password $user_id $password] } {
	# Log the user in.
	ad_user_login -forever=$persistent_cookie_p $user_id
    }

    ad_returnredirect $return_url

} elseif { $email_verified_p == "f" }  { 

    # this user won't be able to use the system until he has answered his email
    # so don't give an auth cookie, but instead tell him 
    # to read your email

    set title "Please read your email"

    ad_return_template
} elseif { $member_state == "needs approval" } {

    # this user won't be able to use the system until an admin has
    # approved him, so don't give an auth cookie, but instead tell him 
    # to wait

    set title "Awaiting Approval"
    set site_link [ad_site_home_link]

    ad_return_template
} 

set notification_address [ad_parameter NewRegistrationEmailAddress "security" [ad_system_owner]]

if {[ad_parameter NotifyAdminOfNewRegistrationsP "security" 0]} {
    # we're supposed to notify the administrator when someone new registers
    ns_sendmail $notification_address $email "New registration at [ad_url]" "
$first_names $last_name ($email) registered as a user of 
[ad_url]
"
}

if { !$double_click_p } {
    
    if { $email_verified_p == "f" } {
	
	set row_id [db_string user_new_2_rowid_for_email "select rowid from users where user_id = :user_id"]
	# the user has to come back and activate their account

	ns_sendmail $email $notification_address "Welcome to [ad_system_name]" "To confirm your registration, please go to [ad_parameter -package_id [ad_acs_kernel_id] SystemURL]/register/email-confirm?[export_url_vars row_id]"
	
    } elseif { [ad_parameter RegistrationProvidesRandomPasswordP "security" 0] ||  [ad_parameter EmailRegistrationConfirmationToUserP "security" 0] } {
	with_catch errmsg {
	    ns_sendmail $email $notification_address "Thank you for visiting [ad_system_name]" "Here's how you can log in at [ad_url]:
	    
Username:  $email
Password:  $password
"
	} {
	    ns_returnerror "error" "$error"
	    ns_log Warning "Error sending registration confirmation to $email in user-new-2"
	}
    }
}

