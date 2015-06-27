# /packages/acs-subsite/www/admin/rel-types/rels-list.tcl

ad_page_contract {

    Displays all relations for the specified rel_type

    @author mbryzek@arsdigita.com
    @creation-date Fri Jan 12 20:52:33 2001
    @cvs-id $Id$

} {
    rel_type:notnull
} -properties {
    context:onevalue
    rel_type_pretty_name:onevalue
    rels:multirow
}

set user_id [ad_conn user_id]
set package_id [ad_conn package_id]

set context [list [list "" "Relationship types"] [[export_vars -base one rel_type] "One type"] "Relations"]

if { ![db_0or1row select_pretty_name {
    select t.pretty_name as rel_type_pretty_name
      from acs_object_types t
     where t.object_type = :rel_type
}] } {
    ad_return_error "Relationship type doesn't exist" "Relationship type \"$rel_type\" doesn't exist"
    return
}

db_multirow rels rels_select {
    select r.rel_id, acs_object.name(r.object_id_one) || ' and ' || acs_object.name(r.object_id_two) as name
      from acs_rels r, acs_object_party_privilege_map perm,
           app_group_distinct_rel_map m
     where perm.object_id = r.rel_id
       and perm.party_id = :user_id
       and perm.privilege = 'read'
       and r.rel_type = :rel_type
       and m.rel_id = r.rel_id
       and m.package_id = :package_id
     order by lower(name)
}

ad_return_template
