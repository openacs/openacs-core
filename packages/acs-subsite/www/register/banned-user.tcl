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
    ad_return_error "Couldn't find your record" "User id $user_id is not in the database.  This is probably our programming bug."
    return
}

if { ![string equal $member_state "banned"] } {
    ad_return_error "Problem with user authentication" "You have encountered a problem with authentication."
    return
}

# User is truely banned
db_release_unused_handles

set system_name [ad_system_name]

ad_return_template
