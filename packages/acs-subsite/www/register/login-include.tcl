# Present a login box
#
# Expects:
#   package_id - optional
#   return_url - optional 
#   email - optional

if { ![exists_and_not_null package_id] } {
    set package_id [ad_conn package_id]
}

if { ![exists_and_not_null email] } {
    set email {}
}

set allow_persistent_login_p [parameter::get -package_id $package_id -parameter AllowPersistentLoginP -default 1]
set persistent_login_p [parameter::get -package_id $package_id -parameter AllowPersistentLoginP -default 1]

set email_forgotten_password_p [parameter::get -package_id $package_id -parameter EmailForgottenPasswordP -default 1]

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
