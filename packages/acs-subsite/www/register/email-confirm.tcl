ad_page_contract {
    @cvs-id $Id$

} {
    token:notnull,trim
    user_id:integer
}

if { ![string equal $token [auth::get_user_secret_token -user_id $user_id]] } {
    set message "Bad token"
    ad_returnredirect [export_vars -base "[subsite::get_element -element url]register/account-closed" { message }]
    ad_script_abort    
} 

auth::set_email_verified -user_id $user_id

acs_user::get -user_id $user_id -array user_info

set export_vars [export_vars -form { { username $user_info(username) } }]
set site_link [ad_site_home_link]
set system_name [ad_system_name]
