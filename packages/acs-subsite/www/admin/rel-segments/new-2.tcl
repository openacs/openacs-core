ad_page_contract {

    Form to create a new relational segment (Use this only if you know
    the relationship type in advance.

    @author mbryzek@arsdigita.com
    @creation-date Mon Dec 11 13:51:21 2000
    @cvs-id $Id$

} {
    group_id:integer,notnull
    rel_type:notnull
    { return_url:localurl "" }
} -properties {
    context:onevalue
    export_vars:onevalue
    group_id:onevalue
    role_pretty_plural:onevalue
    group_name:onevalue
} -validate {
    group_in_scope_p -requires {group_id:notnull} {
        if { ![application_group::contains_party_p -party_id $group_id -include_self]} {
            ad_complain "The group either does not exist or does not belong to this subsite."
        }
    }
    relation_in_scope_p -requires {rel_id:notnull permission_p} {
        if { ![application_group::contains_relation_p -rel_id $rel_id]} {
            ad_complain "The relation either does not exist or does not belong to this subsite."
        }
    }
}

set subsite_group_id [application_group::group_id_from_package_id]


permission::require_permission -object_id $group_id -privilege "read"

set context [list [list "[ad_conn package_url]admin/rel-segments/" "Relational segments"] "Add segment"]

set export_vars [export_vars -form {group_id rel_type return_url}]

set role_pretty_plural [db_string get_pretty_plural {
    select coalesce(pretty_plural, 'Elements') from acs_rel_roles
    where role = (select role_two from acs_rel_types where rel_type = :rel_type)}]

set group_name [group::get_element \
                    -group_id $group_id \
                    -element group_name]

# The role pretty names can be message catalog keys that need
# to be localized before they are displayed
set role_pretty_plural [lang::util::localize $role_pretty_plural]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
