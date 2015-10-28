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

db_multirow rels rels_select {}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
