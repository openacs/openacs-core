ad_page_contract {
    Leave the group
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-08-07
    @cvs-id $Id$
} {
    {return_url "."}
}

ad_maybe_redirect_for_registration

set user_id [ad_conn user_id]
set group_id [application_group::group_id_from_package_id]

set member_p [group::member_p -group_id $group_id -user_id $user_id]

if { $member_p } {

    set rel_id [relation::get_id \
                    -object_id_one $group_id \
                    -object_id_two $user_id]

    db_transaction {
	relation_remove $rel_id
    } on_error {
	ad_return_error "Error creating the relation" "We got the following error while trying to remove the relation: <pre>$errmsg</pre>"
	ad_script_abort
    }

}

ad_returnredirect $return_url
