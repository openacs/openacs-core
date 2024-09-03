ad_page_contract {} {
    object_id:naturalnum,notnull
    user_id:multiple,naturalnum
    return_url:localurl
}

permission::require_permission -object_id $object_id -privilege admin

db_transaction {
    foreach one_user_id $user_id {
        permission::grant -party_id $one_user_id -object_id $object_id -privilege "read"
    }
} on_error {
    ad_return_complaint 1 "We had a problem adding the users you selected. Sorry."
    ad_script_abort
}

ad_returnredirect $return_url
ad_script_abort

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
