ad_page_contract {
    The page restores a user from the deleted state.
    @cvs-id $Id$
} {
    user_id:naturalnum
} -properties {
    site_link:onevalue
    export_vars:onevalue
    email:onevalue
}

if {![db_0or1row user_state_info {
    select member_state, email, rel_id from cc_users where user_id = :user_id
}]} { 
    ad_return_error "[_ acs-subsite.lt_Couldnt_find_your_rec]" "[_ acs-subsite.lt_User_id_user_id_is_no_3]"
    return
}

if { $member_state == "deleted" } {
    
    # they presumably deleted themselves  
    # Note that the only transition allowed if from deleted
    # to authorized.  No other states may be restored

    db_dml member_state_authorized_transistion {
	update membership_rels
	set member_state = 'approved'  
	where rel_id = :rel_id
    }
    
} else {
    ad_return_error "[_ acs-subsite.lt_Problem_with_authenti]" "[_ acs-subsite.lt_There_was_a_problem_w]"
}

set site_link [ad_site_home_link]

# One common problem with login is that people can hit the back button
# after a user logs out and relogin by using the cached password in
# the browser. We generate a unique hashed timestamp so that users
# cannot use the back button.

set time [ns_time]
set token_id [sec_get_random_cached_token_id]
set token [sec_get_token $token_id]
set hash [ns_sha1 "$time$token_id$token"]

set export_vars [export_form_vars return_url time token_id hash email]

set email_password_url "email-password.tcl?user_id=$user_id"

ad_return_template
