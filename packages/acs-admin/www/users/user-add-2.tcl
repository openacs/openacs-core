ad_page_contract {
    Processes a new user created by an admin
    @cvs-id $Id$
} -query {
    user_id
    password
    {referer "/acs-admin/users"}
} -properties {
    context:onevalue
    export_vars:onevalue
    system_name:onevalue
    system_url:onevalue
    first_names:onevalue
    last_name:onevalue
    email:onevalue
    password:onevalue
    administration_name:onevalue
}

set admin_user_id [ad_verify_and_get_user_id]

# Get user info
acs_user::get -user_id $user_id -array user
# easier to work with scalar vars than array
foreach var_name [array names user] {
    set $var_name $user($var_name)
}

if { [empty_string_p $password] } {
    set password [ad_generate_random_string]
}

set administration_name [db_string admin_name "select
first_names || ' ' || last_name from persons where person_id = :admin_user_id"]

set context [list [list "./" "Users"] "Notify added user"]
set system_name [ad_system_name]
set export_vars [export_form_vars email first_names last_name user_id]
set system_url [ad_parameter -package_id [ad_acs_kernel_id] SystemURL ""].

ad_return_template
