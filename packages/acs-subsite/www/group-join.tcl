ad_page_contract {
    Join/request membership for this group

    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-08-07
    @cvs-id $Id$
} {
    {return_url "."}
}

auth::require_login

set user_id [ad_conn user_id]
set group_id [application_group::group_id_from_package_id]
set join_policy [group::join_policy -group_id $group_id]

set member_p [group::member_p -group_id $group_id -user_id $user_id]

# Check that they're not already a member
if { !$member_p } {

    # Create the relation
    
    set rel_type "membership_rel"
    
    set member_state [group::default_member_state -join_policy $join_policy -create_p 0]
    
    db_transaction {
        set rel_id [relation_add -member_state $member_state $rel_type $group_id $user_id]
    } on_error {
        ad_return_error "Error creating the relation" "We got the following error message while trying to create this relation: <pre>$errmsg</pre>"
        ad_script_abort
    }

}

ad_returnredirect $return_url
