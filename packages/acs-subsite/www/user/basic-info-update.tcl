ad_page_contract {
    Displays form for currently logged in user to update his/her
 personal information

    @author Unknown
    @creation-date Unknown
    @cvs-id $Id$
} {
    
    { return_url "" }
    { user_id "" }
} -properties {
    site_link:onevalue
    export_vars:onevalue
    first_names:onevalue
    last_name:onevalue
    screen_name:onevalue
    url:onevalue
    email:onevalue
    bio:onevalue
}

set current_user_id [ad_verify_and_get_user_id]

if [empty_string_p $user_id] {
    set user_id $current_user_id
}

ad_require_permission $user_id "write"

db_1row general_info {}

set bio [person::get_bio -person_id $user_id]

db_release_unused_handles

set site_link [ad_site_home_link]
set export_vars [export_form_vars return_url user_id]

