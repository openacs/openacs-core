ad_page_contract {
    Handles users where we are waiting for email verification.
    
    @cvs-id $Id$

} {
    user_id:integer
} -properties {
    email:onevalue
}

if {![db_0or1row register_user_state_properties {
    select member_state, email, row_id 
    from cc_users
    where user_id = :user_id and
    email_verified_p = 'f' }]} { 
    ns_log Notice "Couldn't find $user_id in /register/awaiting-email-verification"
    ad_return_error "Couldn't find your record" "User id $user_id is not found in the need email verification state."
    ad_script_abort
}


if ![ad_parameter RegistrationRequiresEmailVerificationP "security" 0] {
    # we are not using the "email required verfication" system
    # they should not be in this state

    db_dml register_member_state_authorized_set "update users set 
email_verified_p = 't'
where user_id = :user_id" 
    if {$member_state == "approved"} {
	# we don't require administration approval to get to get authorized
	ad_returnredirect "index?[export_url_vars email]"
        ad_script_abort
    } else {
        ad_returnredirect "awaiting-approval?[export_url_vars user_id]"
        ad_script_abort
    }
}

db_release_unused_handles

# we are waiting for the user to verify their email -- return template

ad_return_template

# Send them the mail for them to come back and activate their account
ns_sendmail  "$email" "[ad_parameter NewRegistrationEmailAddress "security"]" "Welcome to [ad_system_name]" "To confirm your registration, please go to [ad_parameter -package_id [ad_acs_kernel_id] SystemURL]/register/email-confirm?[export_url_vars row_id]"

