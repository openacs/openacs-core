# /packages/mbryzek-subsite/www/admin/groups/rel-type-add.tcl

ad_page_contract {

    Displays relationship types to add as an allowable one

    @author mbryzek@arsdigita.com
    @creation-date Tue Jan  2 12:08:12 2001
    @cvs-id $Id$

} {
    group_id:integer,notnull
    { return_url "" }
} -properties {
    context:onevalue
    export_vars:onevalue
    return_url_enc:onevalue
    primary_rels:multirow
}

set context [list [list "[ad_conn package_url]admin/groups/" "Groups"] [list "one?[ad_export_vars group_id]" "One Group"] "Add relation type"]
set return_url_enc [ad_urlencode "[ad_conn url]?[ad_conn query]"]

# Select out all the relationship types that are not currently
# specified for this group. Note that we use acs_object_types so that
# we can probably indent subtypes. We use acs_rel_types to limit our
# selection to acceptable relationship types.

# We need this group's type
db_1row select_group_type {
    select o.object_type as group_type
      from acs_objects o
     where o.object_id = :group_id
}

db_multirow primary_rels select_primary_relations {
    select replace(lpad(' ', (t.type_level - 1) * 4), ' ', '&nbsp;') as indent,
           t.pretty_name, t.rel_type
      from (select t.pretty_name, t.object_type as rel_type, level as type_level
              from acs_object_types t
             where t.object_type not in (select g.rel_type 
                                           from group_rels g 
                                          where g.group_id = :group_id)
           connect by prior t.object_type = t.supertype
             start with t.object_type in ('membership_rel', 'composition_rel')) t,
           acs_rel_types rel_type
     where t.rel_type = rel_type.rel_type
       and (rel_type.object_type_one = :group_type 
            or acs_object_type.is_subtype_p(rel_type.object_type_one, :group_type) = 't')
}

set export_vars [ad_export_vars -form {group_id return_url}]

ad_return_template
