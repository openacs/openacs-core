ad_page_contract {
    Make ordinary members.
} {
    {user_id:multiple ""}
}

set group_id [application_group::group_id_from_package_id]

permission::require_permission -object_id $group_id -privilege "admin"

# TODO:
# Check if you're making yourself an non-admin?

db_transaction {
    foreach one_user_id $user_id {
        db_1row get_rel_id {}
        relation_remove $rel_id
    }
} on_error {
    ad_return_error "Error creating the relation" "We got the following error message while trying to create this relation: <pre>$errmsg</pre>"
    ad_script_abort
}

ad_returnredirect .
ad_script_abort
