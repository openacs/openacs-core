ad_page_contract {
    Adding a user by an administrator

    @cvs-id $Id$
} -query {
    {referer "/acs-admin/users"}
} -properties {
    context:onevalue
    export_vars:onevalue
}

set context [list [list "." "Users"] "Add user"]

set next_url user-add-2
