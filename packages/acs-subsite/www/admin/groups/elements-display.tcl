# /packages/acs-subsite/www/admin/groups/elements-display.tcl

ad_page_contract {

    Displays all elements in a group with a specified rel_type

    @author mbryzek@arsdigita.com
    @creation-date Mon Jan  8 14:01:48 2001
    @cvs-id $Id$

} {
    group_id:integer,notnull
    rel_type:notnull
    {member_state ""}
} -properties {
    context:onevalue
    create_p:onevalue
    group_id:onevalue
    group_name:onevalue
    role_pretty_plural:onevalue
    rel_type_enc:onevalue
    return_url_enc:onevalue
    member_state:onevalue
    possible_member_states:multirow
} -validate {
    groups_exists_p -requires {group_id:notnull} {
        if { ![permission::permission_p -object_id $group_id -privilege "read"] } {
            ad_complain "The group either does not exist or you do not have permission to view it"
        }
    }
}

set user_id [ad_conn user_id]
set create_p [permission::permission_p -party_id $user_id -object_id $group_id -privilege "create"]

set add_url [export_vars -base "../relations/add" {
    group_id rel_type {return_url "[ad_conn url]?[ad_conn query]"}}]

# Select out the group name and the group's object type. Note we can
# use 1row because the validate filter above will catch missing groups
db_1row group_and_rel_info {
    select (select group_name from groups
            where group_id = :group_id) as group_name,
           (select pretty_name from acs_object_types
            where object_type = :rel_type) as rel_type_pretty_name,
           r.pretty_plural as role_pretty_plural,
           r.pretty_name as role_pretty_name
      from acs_rel_types rel_types,
           acs_rel_roles r
     where r.role = rel_types.role_two
       and rel_types.rel_type = :rel_type
}

# The role pretty names can be message catalog keys that need
# to be localized before they are displayed
set role_pretty_name [lang::util::localize $role_pretty_name]
set role_pretty_plural [lang::util::localize $role_pretty_plural]

set context [list [list "[ad_conn package_url]admin/groups/" "Groups"] [list [export_vars -base one group_id] "One Group"] "All $role_pretty_plural"]

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
