ad_page_contract {
    Updates the users password if 
    <ul>
    <li>password_old is correct
    <li>password_1 matches password_2

    @cvs-id $Id$
} -query {
    password_1
    password_2
    {password_old ""}
    {user_id ""}
    {return_url ""}
} -properties {
    return_url:onevalue
    site_link:onevalue
}

set current_user_id [ad_verify_and_get_user_id]

if {[empty_string_p $user_id]} {
    set user_id $current_user_id
    set admin_enabled_p 0
    ad_require_permission $user_id "write"
} else {
    set admin_enabled_p 1
    ad_require_permission $user_id "admin"
}

set bind_vars [ad_tcl_vars_to_ns_set user_id password_1]

set exception_text ""
set exception_count 0

if {!$admin_enabled_p && ![ad_check_password $user_id $password_old] } {
    ns_log "Notice" "password matched"
    append exception_text "<li>Your current password does not match what you entered in the form\n"
    incr exception_count
}


if { ![info exists password_1] || [empty_string_p $password_1] } {
    append exception_text "<li>You need to type in a password\n"
    incr exception_count
}

if { ![info exists password_2] || [empty_string_p $password_2] } {
    append exception_text "<li>You need to confirm the password that you typed.  (Type the same thing again.) \n"
    incr exception_count
}


if { [string compare $password_2 $password_1] != 0 } {
    append exception_text "<li>Your passwords don't match!  Presumably, you made a typo while entering one of them.\n"
    incr exception_count
}


if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

if [empty_string_p $return_url] {
    set return_url [ad_parameter -package_id [ad_acs_kernel_id] "HomeURL"]
    set return_link "return to [ad_pvt_home_link]"
} else {
    set return_link "<a href=\"$return_url\">return</a>"
}

if [catch {ad_change_password $user_id $password_1} errmsg] {
    ad_return_error "Ouch!"  "Wasn't able to change your password for
unknown reasons.  This is probably our fault. Please contact the
system administrator."
}

set site_link [ad_site_home_link]

ad_returnredirect $return_url
