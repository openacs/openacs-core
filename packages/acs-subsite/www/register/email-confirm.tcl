ad_page_contract {
    @cvs-id $Id$

} {
    token:notnull,trim
    user_id:integer
}

if {![db_0or1row userp {select 1 from users where user_id = :user_id}]
    || ![string equal $token [auth::get_user_secret_token -user_id $user_id]] } {
    set title "Bad token"
    set message "The link given to authenticate your email was invalid."
    ad_return_template /packages/acs-subsite/lib/message
} else {
    auth::set_email_verified -user_id $user_id

    acs_user::get -user_id $user_id -array user_info

    set export_vars [export_vars -form { { username $user_info(username) } }]
    set site_link [ad_site_home_link]
    set system_name [ad_system_name]
}
