ad_page_contract {
    Remove member(s).
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-02
    @cvs-id $Id$
} {
    rel_id:integer,multiple
}

set group_id [application_group::group_id_from_package_id]

ad_require_permission $group_id "admin"

foreach one_rel_id $rel_id {
    db_transaction {
	relation_remove $one_rel_id
    } on_error {
	ad_return_error "Error creating the relation" "We got the following error while trying to remove the relation: <pre>$errmsg</pre>"
	ad_script_abort
    }
}

ad_returnredirect .
