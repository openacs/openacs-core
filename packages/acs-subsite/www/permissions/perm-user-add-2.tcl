ad_page_contract {} {
    object_id
    user_id:multiple,integer
    return_url
}

ad_require_permission $object_id admin

db_transaction {
    foreach one_user_id $user_id {
        db_exec_plsql add_user {}
    }
} on_error {
    ad_return_complaint 1 "We had a problem adding the users you selected. Sorry."
}

ad_returnredirect $return_url
