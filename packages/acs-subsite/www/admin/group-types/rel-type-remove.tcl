# /packages/mbryzek-subsite/www/admin/group-types/rel-type-remove.tcl

ad_page_contract {

    Confirmation to remove an allowable relation type

    @author mbryzek@arsdigita.com
    @creation-date Sun Dec 10 16:40:11 2000
    @cvs-id $Id$

} {
    group_rel_type_id:naturalnum,notnull
    { return_url:localurl "" }
} -properties {
    context:onevalue
    rel_pretty_name:onevalue
    group_type_pretty_name:onevalue
    export_vars:onevalue
}

if { ![db_0or1row select_info {
    select g.rel_type, g.group_type, 
           t.pretty_name as rel_pretty_name, t2.pretty_name as group_type_pretty_name
      from acs_object_types t, acs_object_types t2, group_type_rels g
     where g.group_rel_type_id = :group_rel_type_id
       and t.object_type = g.rel_type
       and t2.object_type = g.group_type
}] } {
    ad_return_error "Relation already removed." "Please back up and reload"
    return
}

set export_vars [export_vars -form {group_rel_type_id return_url}]
set context [list [list "[ad_conn package_url]admin/group-types/" "Group types"] [list [export_vars -base one {group_type}] "One type"] "Remove relation type"]

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
