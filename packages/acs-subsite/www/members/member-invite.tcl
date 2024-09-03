ad_page_contract {
    Invite new member.

    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-02
    @cvs-id $Id$
}

subsite::assert_user_may_add_member

set group_id [application_group::group_id_from_package_id]
set admin_p [permission::permission_p -object_id $group_id -privilege "admin"]

set page_title "Invite Member to [ad_conn instance_name]"
set context [list [list "." "Members"] "Invite"]

group::get \
    -group_id $group_id \
    -array group_info

# if we are at main site, only show the form for creating a new user

set subsite_p [expr { [subsite::main_site_id] ne [ad_conn package_id] }]

ad_form -name user_search -cancel_url . -form {
    {user_id:search
        {result_datatype integer}
        {label {Search for user}}
        {help_text {Type part of the name or email of the user you would like to add}}
        {search_query {
            select first_names || ' ' || last_name || ' (' || email || ')' as name, user_id
              from cc_users u
             where upper(coalesce(first_names || ' ', '') ||
                   coalesce(last_name || ' ', '') ||
                   email || ' ' ||
                   coalesce(screen_name, '')) like upper('%'||:value||'%')
               and not exists (select 1 from acs_rels
                                where object_id_one = $group_id
                                  and object_id_two = u.user_id
                                  and rel_type = 'membership_rel')
            order  by name
        }}
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
    set create_p [permission::permission_p -object_id $group_id -privilege "create"]

    if { $group_info(join_policy) eq "closed" && !$create_p} {
        ad_return_forbidden "Cannot invite members" "I'm sorry, but you're not allowed to invite members to this group"
        ad_script_abort
    }

    # Only admins can add non-membership_rel members
    if { !$admin_p } {
        set rel_type "membership_rel"
    }

    if { ![group::member_p -user_id $user_id -group_id $group_id] } {
        ad_try {
            group::add_member \
                -group_id $group_id \
                -user_id $user_id \
                -rel_type $rel_type
        } on error {errmsg} {
            form set_error user_search user_id "Error adding user to community: $errmsg"
            ns_log Error "Error adding user $user_id to community group $group_id: $errmsg\n$::errorInfo"
            break
        }
    }
} -after_submit {
    ad_returnredirect .
    ad_script_abort
}


ad_form -action user-new -name user_create -cancel_url . -form {
    {email:text(email)
        {label "Email"}
        {help_text "Type the email of the person you would like to add"}
        {html {size 50}}
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
