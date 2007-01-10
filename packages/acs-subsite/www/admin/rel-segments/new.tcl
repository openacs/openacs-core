# /packages/mbryzek-subsite/www/admin/rel-segments/new.tcl

ad_page_contract {

    Form to create a new relational segment

    @author mbryzek@arsdigita.com
    @creation-date Mon Dec 11 13:51:21 2000
    @cvs-id $Id$

} {
    group_id:integer,notnull
    { rel_type:trim "" }
    { return_url "" }
} -properties {
    context:onevalue
    export_vars:onevalue
    group_id:onevalue
    primary_rels:multirow
    group_name:onevalue
    subsite_group_id:onevalue
} -validate {
    group_in_scope_p -requires {group_id:notnull} {
	if { ![application_group::contains_party_p -party_id $group_id -include_self]} {
	    ad_complain "The group either does not exist or does not belong to this subsite."
	}
    }
}

set subsite_group_id [application_group::group_id_from_package_id]

# If the user has specified a rel_type, redirect to new-2
if { $rel_type ne "" } {
    ad_returnredirect new-2?[ad_export_vars {group_id rel_type return_url}]
    ad_script_abort
} 

ad_require_permission $group_id "read"

set context [list [list "" "Relational segments"] "Add segment"]

set export_vars [ad_export_vars -form {group_id return_url}]
# Select out all relationship types
db_multirow rel_types select_relation_types {
    select t.pretty_name, t.object_type as rel_type,
    replace(lpad(' ', (level - 1) * 4), ' ', '&nbsp;') as indent
    from acs_object_types t
    where t.object_type not in (select s.rel_type from rel_segments s where s.group_id = :group_id)
    connect by prior t.object_type = t.supertype
    start with t.object_type in ('membership_rel', 'composition_rel')
    order by lower(t.pretty_name) desc
}

db_1row select_basic_info {
    select acs_group.name(:group_id) as group_name
      from dual
}

ad_return_template
