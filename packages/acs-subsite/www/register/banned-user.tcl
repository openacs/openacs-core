ad_page_contract {
    
    Page to send banned users when they login.
    @cvs-id $Id$
} {
    user_id:naturalnum
} -properties {
    system_name:onevalue
}

# Verify that the user is in the banned state
if { ![db_0or1row register_banned_member_state {
    select member_state from cc_users 
    where user_id = :user_id }
      ]} {
    ad_return_error "[_ acs-subsite.lt_Couldnt_find_your_rec_1]"
    return
}

if { ![string equal $member_state "banned"] } {
    ad_return_error "[_ acs-subsite.lt_Problem_with_user_aut]" "[_ acs-subsite.lt_You_have_encountered_]"
    return
}

# User is truly banned
db_release_unused_handles

set system_name [ad_system_name]

ad_return_template
