ad_page_contract {
    The page restores a user from the deleted state.
    @cvs-id $Id$
} {
    user_id:naturalnum
} -properties {
    site_link:onevalue
    export_vars:onevalue
    user_id:onevalue
    email:onevalue
}

if {![db_0or1row user_state_info {
    select member_state, email, rel_id from cc_users where user_id = :user_id
}]} { 
    ad_return_error "Couldn't find your record" "User id $user_id is not in the database.  This is probably out programming bug."
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
    ad_return_error "Problem with authentication" "There was a problem with authenticating your account"
}

set site_link [ad_site_home_link]
set export_vars [export_form_vars user_id email]

ad_return_template
