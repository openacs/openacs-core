ad_page_contract {
    Let's the user change his/her password.  Asks
    for old password, new password, and confirmation.

    @version $Id$
} {
    {user_id ""}
    {return_url ""}
    {password_old ""}
} -properties {
    first_names:onevalue
    last_name:onevalue
    admin_enabled_p:onevalue
    export_vars:onevalue
    site_link:onevalue
}

if {[empty_string_p $user_id]} {
    set user_id [ad_verify_and_get_user_id]
    permission::require_permission -party_id $user_id -object_id $user_id -privilege "write"
} else {
    permission::require_permission -object_id $user_id -privilege "admin"
}

set admin_p [permission::permission_p -object_id $user_id -privilege "admin"]

db_1row user_information {}

set site_link [ad_site_home_link]

ad_return_template
                 