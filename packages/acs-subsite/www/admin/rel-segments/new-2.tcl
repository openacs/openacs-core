# /packages/mbryzek-subsite/www/admin/rel-segments/new-2.tcl

ad_page_contract {

    Form to create a new relational segment (Use this only if you know
    the relationship type in advance.

    @author mbryzek@arsdigita.com
    @creation-date Mon Dec 11 13:51:21 2000
    @cvs-id $Id$

} {
    group_id:integer,notnull
    rel_type:notnull
    { return_url "" }
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

db_1row select_basic_info {
    select acs_group.name(:group_id) as group_name,
    nvl(acs_rel_type.role_pretty_plural(t.role_two),'Elements') as role_pretty_plural
      from acs_rel_types t
     where t.rel_type = :rel_type
}

# The role pretty names can be message catalog keys that need
# to be localized before they are displayed
set role_pretty_plural [lang::util::localize $role_pretty_plural]    

ad_return_template
