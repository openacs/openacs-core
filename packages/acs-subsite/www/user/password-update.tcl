ad_page_contract {
    Let's the user change his/her password.  Asks
    for old password, new password, and confirmation.

    @cvs-id $Id$
} {
    {user_id ""}
    {return_url ""}
} -properties {
    first_names:onevalue
    last_name:onevalue
    admin_enabled_p:onevalue
    export_vars:onevalue
    site_link:onevalue
}

set current_user_id [ad_verify_and_get_user_id]

if [empty_string_p $user_id] {
    set user_id $current_user_id
    set admin_enabled_p 0
    ad_require_permission $user_id "write"
} else {
    set admin_enabled_p 1
    ad_require_permission $user_id "admin"
}

set bind_vars [ad_tcl_vars_to_ns_set user_id]

db_1row user_information "select first_names,
last_name, email, url from cc_users where user_id=:user_id" -bind $bind_vars

if {$admin_enabled_p} {
    set export_vars [export_form_vars return_url user_id]
} else {
    set export_vars [export_form_vars return_url]
}

set site_link [ad_site_home_link]

ad_return_template
