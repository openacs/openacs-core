ad_page_contract {

    A page to send deleted users to.
    
    @cvs-id $Id$
} { 
    user_id:naturalnum
} -properties {
    site_link:onevalue
    user_id:onevalue
    member_state:onevalue
}

if { ![db_0or1row register_deleted_member_state {
    select member_state from cc_users where user_id = :user_id
}] } {

    ad_return_error "Couldn't find your record" "User id $user_id is not in the database.  This is probably our programming bug."
    return
}

db_release_unused_handles

if { $member_state != "deleted" } {
    ad_return_error "Problem with authentication" "You have encountered a problem with authentication"
}

set site_link [ad_site_home_link]

ad_return_template
