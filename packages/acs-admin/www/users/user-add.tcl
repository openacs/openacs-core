ad_page_contract {
    Adding a user by an administrator

    @cvs-id $Id$
} -query {
    {referer "/acs-admin/users"}
} -properties {
    context_bar:onevalue
    export_vars:onevalue
}

set context_bar [ad_admin_context_bar [list "index.tcl" "Users"] "Add user"]

# generate unique key here so we can handle the "user hit s" case
set user_id [db_nextval acs_object_id_seq]
set export_vars [export_form_vars user_id]

ad_return_template
