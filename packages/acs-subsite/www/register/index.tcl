ad_page_contract {
    Prompt the user for email and password.
    @cvs-id $Id$
} {
    { email "" }
    return_url:optional
} -properties {
    system_name:onevalue
    export_vars:onevalue
    email:onevalue
    old_login_process:onevalue
    allow_persistent_login_p:onevalue
    persistent_login_p:onevalue
}

set old_login_process [parameter::get -parameter SeparateEmailPasswordPagesP -default 0]
set allow_persistent_login_p [parameter::get -parameter AllowPersistentLoginP -default 1]
set persistent_login_p [parameter::get -parameter AllowPersistentLoginP -default 1]

set email_forgotten_password_p [parameter::get -parameter EmailForgottenPasswordP -default 1]

if {![info exists return_url]} {
    set return_url [ad_pvt_home]
}

set system_name [ad_system_name]

# One common problem with login is that people can hit the back button
# after a user logs out and relogin by using the cached password in
# the browser. We generate a unique hashed timestamp so that users
# cannot use the back button.

set time [ns_time]
set token_id [sec_get_random_cached_token_id]
set token [sec_get_token $token_id]
set hash [ns_sha1 "$time$token_id$token"]

set export_vars [export_vars -form {return_url time token_id hash}]

ad_return_template
