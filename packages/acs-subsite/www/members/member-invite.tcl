ad_page_contract {
    Invite new member.
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-02
    @cvs-id $Id$
}

set group_id [application_group::group_id_from_package_id]

set admin_p [ad_permission_p -user_id [ad_conn user_id] $group_id "admin"]

if { !$admin_p && ![parameter::get -parameter "MembersCanInviteMembersP" -default 0] } {
    ad_return_forbidden "Cannot invite members" "I'm sorry, but you're not allowed to invite members to this group"
    ad_script_abort
}

set page_title "Inivite Member to [ad_conn instance_name]"
set context [list [list "." "Members"] "Invite"]

db_1row group_info {
    select group_name, join_policy
    from groups
    where group_id = :group_id
}

ad_form -name user_search -cancel_url . -form {
    {user_id:search
        {result_datatype integer}
        {label {Search for user}}
        {help_text {Type part of the name or email of the user you would like to add}}
        {search_query {[db_map user_search]}}
    }
}

# Only admins can add non-membership_rel members
if { $admin_p } {
    ad_form -extend -name user_search -form {
        {rel_type:text(select)
            {label "Role"}
            {options {[group::get_rel_types_options -group_id $group_id]}}
        }
    }
}

ad_form -extend -name user_search -on_submit {
    set create_p [group::permission_p -privilege create $group_id]
    
    if { [string equal $join_policy "closed"] && !$create_p} {
        ad_return_forbidden "Cannot invite members" "I'm sorry, but you're not allowed to invite members to this group"
        ad_script_abort
    }

    # Only admins can add non-membership_rel members
    if { !$admin_p } {
        set rel_type "membership_rel"
    }

    set rel_exists_p [db_0or1row select_existing_rel { 
        select r.rel_id as existing_rel_id,
               r.rel_type as existing_rel_type
        from   acs_rels r
        where  object_id_one = :group_id
        and    object_id_two = :user_id
    }]
    
    if { $rel_exists_p } {
        # This relationship already exists. You shouldn't change user type here
        # Ignore, we're done
        ad_returnredirect .
        ad_script_abort
    }

    set member_state [group::default_member_state -join_policy $join_policy -create_p $create_p]

    db_transaction {
	set rel_id [relation_add -member_state $member_state $rel_type $group_id $user_id]
    } on_error {
	ad_return_error "Error creating the relation" "We got the following error message while trying to create this relation: <pre>$errmsg</pre>"
	ad_script_abort
    }
    ad_returnredirect .
    ad_script_abort
}


ad_form -action user-new -name user_create -cancel_url . -form {
    {email:text
        {label "Email"}
        {help_text "Type the email of the person you would like to add"}
        {html {size 50}}
    }
}
