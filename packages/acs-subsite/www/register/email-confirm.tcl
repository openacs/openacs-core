ad_page_contract {
    @cvs-id $Id$

} {
    row_id:notnull,trim
    user_id
}

set token [auth::get_user_secret_token -user_id $user_id]

if { [string equal $token $row_id] } {
    ad_return_error "[_ acs-subsite.lt_Couldnt_find_your_rec]" "[_ acs-subsite.lt_Row_id_row_id_is_not_]"
    return
} 

auth::confirm_email -user_id $user_id
acs_user::get -user_id $user_id -array user_info

set export_vars [export_form_vars email]
set email $user_info(email)
set site_link [ad_site_home_link]
set system_name [ad_system_name]
