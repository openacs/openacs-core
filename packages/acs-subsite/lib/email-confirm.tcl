if {![db_0or1row userp {select 1 from users where user_id = :user_id}]
    || $token ne [auth::get_user_secret_token -user_id $user_id] } {
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

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
