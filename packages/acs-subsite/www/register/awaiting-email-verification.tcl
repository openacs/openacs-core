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
    ad_return_error "[_ acs-subsite.lt_Couldnt_find_your_rec]" "[_ acs-subsite.lt_User_id_user_id_is_no_1]"
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
# Variables used in the email message
set system_name [ad_system_name]
set confirmation_url "[ad_parameter -package_id [ad_acs_kernel_id] SystemURL]/register/email-confirm?[export_url_vars row_id]"
ns_sendmail  "$email" "[ad_parameter NewRegistrationEmailAddress "security"]" "[_ acs-subsite.lt_Welcome_to_system_nam]" "[_ acs-subsite.lt_To_confirm_your_regis]"
