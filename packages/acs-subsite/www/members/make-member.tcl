ad_page_contract {
    Make ordinary members.
} {
    {rel_id:multiple ""}
}

set group_id [application_group::group_id_from_package_id]

ad_require_permission $group_id "admin"

db_1row group_info {
    select group_name, join_policy
    from groups
    where group_id = :group_id
}

set create_p [group::permission_p -privilege create $group_id]

if { [string equal $join_policy "closed"] && !$create_p} {
    ad_return_forbidden "Cannot make admin members" "I'm sorry, but you're not allowed to make admin members in this group"
    ad_script_abort
}

# TODO:
# Check if you're making yourself an non-admin

db_transaction {
    foreach one_rel_id $rel_id {
        db_1row select_rel_info {
            select rel_type as existing_rel_type,
                   object_id_two as user_id
            from   acs_rels
            where  rel_id = :one_rel_id
        }

        if { [string equal $existing_rel_type "membership_rel"] } {
            # Already a member, skip
            continue
        }
        
        set member_state [group::default_member_state -join_policy $join_policy -create_p $create_p]
        
        # Delete the old relation
	relation_remove $one_rel_id
        
        # Add the new relation
	set rel_id [relation_add -member_state $member_state "membership_rel" $group_id $user_id]

    }
} on_error {
    ad_return_error "Error creating the relation" "We got the following error message while trying to create this relation: <pre>$errmsg</pre>"
    ad_script_abort
}

ad_returnredirect .
ad_script_abort
