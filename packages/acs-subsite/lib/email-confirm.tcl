ad_include_contract {
    Verify users's email by checking the authentication token.
    People normally come here from a confirmation email.
} {
    user_id:integer,notnull
    token:word,notnull
}

set user [acs_user::get_user_info -user_id $user_id]
if {$user eq ""
    || $token ne [auth::get_user_secret_token -user_id $user_id] } {
    set title "Bad token"
    set message "The link given to authenticate your email was invalid."
    ad_return_template /packages/acs-subsite/lib/message
    ad_script_abort
} else {
    auth::set_email_verified -user_id $user_id
    set member_state [acs_user::get_user_info -user_id $user_id -element member_state]

    set export_vars [export_vars -form { { username "[dict get $user username]" } }]
    set site_link [ad_site_home_link]
    set system_name [ad_system_name]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
