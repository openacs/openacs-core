# /packages/mbryzek-subsite/www/admin/rel-types/one.tcl

ad_page_contract {

    Shows information about one relationship type

    @author mbryzek@arsdigita.com
    @creation-date Sun Dec 10 17:24:21 2000
    @cvs-id $Id$

} {
    rel_type:notnull
} -properties {
    context:onevalue
    rel_type:onevalue
    rel_type_enc:onevalue
    rel_type_pretty_name:onevalue
    dynamic_p:onevalue
    rels:multirow
    attributes:multirow
    properties:onerow
    return_url_enc:onevalue
}

set return_url [ad_conn url]?[ad_conn query] 
set return_url_enc [ad_urlencode $return_url]
set rel_type_enc [ad_urlencode $rel_type]

set package_id [ad_conn package_id]

set context [list [list "./" "Relationship types"] "One type"]

if { ![db_0or1row select_pretty_name {
    select t.pretty_name as rel_type_pretty_name, t.table_name, t.id_column, t.dynamic_p
      from acs_object_types t
     where t.object_type = :rel_type
}] } {
    ad_return_error "Relationship type doesn't exist" "Relationship type \"$rel_type\" doesn't exist"
    return
}

db_1row select_rel_type_properties {} -column_array properties


set user_id [ad_conn user_id]

# We display up to 25 relations, and then offer a link for the rest.

# Pull out all the relations of this type 
db_multirow rels rels_select {}


db_multirow attributes attributes_select {
    select a.attribute_id, a.pretty_name
      from acs_attributes a
     where a.object_type = :rel_type
}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
