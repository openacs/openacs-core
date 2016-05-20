# /packages/mbryzek-subsite/www/admin/rel-type/add.tcl

ad_page_contract {

    Add a permissible relation type to a group type

    @author mbryzek@arsdigita.com
    @creation-date Sun Nov 12 17:50:04 2000
    @cvs-id $Id$

} {
    object_type:notnull
    { return_url:localurl "" }
} -properties {
    context:onevalue
    export_form_vars:onevalue
    export_url_vars:onevalue
    primary_rels:multirow
}

set context [list "Add relation type"]
set constraint_id [db_nextval "acs_object_id_seq"]
set export_form_vars [export_vars -form {constraint_id object_type return_url}]
set export_url_vars [export_vars {constraint_id object_type return_url}]

db_multirow primary_rels select_primary_relations {
    select o.object_type as rel_type, o.pretty_name
      from acs_object_types o
     where o.object_type in ('composition_rel','membership_rel')
       and o.object_type not in (select g.rel_type from group_type_allowed_rels g where g.group_type = :object_type)
}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
