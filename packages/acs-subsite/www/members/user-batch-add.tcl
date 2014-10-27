ad_page_contract {
    Interface for specifying a list of users to sign up as a batch
    @cvs-id $Id$
} -properties {
    context:onevalue
    system_name:onevalue
    system_url:onevalue
    administration_name:onevalue
    admin_email:onevalue
}

subsite::assert_user_may_add_member

set admin_user_id [ad_conn user_id]
set admin_email [db_string unused "select email from 
parties where party_id = :admin_user_id"]
set administration_name [db_string admin_name "select
first_names || ' ' || last_name from persons where person_id = :admin_user_id"]

set context [list [list "./" "Users"] "Notify added user"]
set system_name [ad_system_name]
set export_vars [export_vars -form {email first_names last_name user_id}]
set system_url [parameter::get -package_id [ad_acs_kernel_id] -parameter SystemURL -default ""].

ad_return_template
