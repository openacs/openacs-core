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

    ad_return_error "[_ acs-subsite.lt_Couldnt_find_your_rec]" "[_ acs-subsite.lt_User_id_user_id_is_no_2]"
    return
}

db_release_unused_handles

if { $member_state != "deleted" } {
    ad_return_error "[_ acs-subsite.lt_Problem_with_authenti]" "[_ acs-subsite.lt_You_have_encountered__1]"
}

set site_link [ad_site_home_link]

ad_return_template
