ad_page_contract {
    The page restores a user from the deleted state.
    @cvs-id $Id$
} {
    {return_url {[ad_pvt_home]}}
}

set page_title [_ acs-subsite.Account_reopened_title]
set context [list [list [ad_pvt_home] [ad_pvt_home_name]] $page_title]

# We do require authentication, though their account will be closed
set user_id [auth::require_login -account_status closed]

set member_state [acs_user::get_element -user_id $user_id -element member_state]

switch $member_state {
    deleted {
        
        # They presumably deleted themselves  
        # Note that the only transition allowed if from deleted
        # to authorized.  No other states may be restored
        
        acs_user::approve -user_id $user_id
    } 
    approved {
        # May be a double-click
    }
    default {
        ad_return_error "[_ acs-subsite.lt_Problem_with_authenti]" "[_ acs-subsite.lt_There_was_a_problem_w]"
    }
}

auth::verify_account_status

# Used in a message key
set system_name [ad_system_name]
