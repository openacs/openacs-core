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

db_1row select_rel_type_properties {
    select t1.pretty_name as object_type_one_pretty_name, 
           r.object_type_one, acs_rel_type.role_pretty_name(r.role_one) as role_one_pretty_name, 
           r.role_one, r.min_n_rels_one, r.max_n_rels_one,
           t2.pretty_name as object_type_two_pretty_name, 
           r.object_type_two, acs_rel_type.role_pretty_name(r.role_two) as role_two_pretty_name, 
           r.role_two, r.min_n_rels_two, r.max_n_rels_two
      from acs_rel_types r, acs_object_types t1, acs_object_types t2
     where r.rel_type = :rel_type
       and r.object_type_one = t1.object_type
       and r.object_type_two = t2.object_type
} -column_array properties


set user_id [ad_conn user_id]

# We display up to 25 relations, and then offer a link for the rest.

# Pull out all the relations of this type 
db_multirow rels rels_select {
    select inner.* 
      from (select r.rel_id, acs_object.name(r.object_id_one) || ' and ' || acs_object.name(r.object_id_two) as name
              from acs_rels r, acs_object_party_privilege_map perm,
                   app_group_distinct_rel_map m
             where perm.object_id = r.rel_id
               and perm.party_id = :user_id
               and perm.privilege = 'read'
               and r.rel_type = :rel_type
               and m.rel_id = r.rel_id
               and m.package_id = :package_id
             order by lower(acs_object.name(r.object_id_one)), lower(acs_object.name(r.object_id_two))) inner
    where rownum <= 26
}


db_multirow attributes attributes_select {
    select a.attribute_id, a.pretty_name
      from acs_attributes a
     where a.object_type = :rel_type
}

ad_return_template
