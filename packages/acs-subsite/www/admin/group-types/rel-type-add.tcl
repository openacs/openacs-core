# /packages/mbryzek-subsite/www/admin/group-types/rel-type-add.tcl

ad_page_contract {

    Shows list of available rel types to add for this group type

    @author mbryzek@arsdigita.com
    @creation-date Sun Dec 10 16:50:58 2000
    @cvs-id $Id$

} {
    group_type:trim,notnull
    { return_url "" }
} -properties {
    context:onevalue
    return_url_enc:onevalue
    export_vars:onevalue
    primary_rels:multirow
}

set return_url_enc [ad_urlencode "[ad_conn url]?[ad_conn query]"]
set context [list [list "[ad_conn package_url]admin/group-types/" "Group types"] [list one?[ad_export_vars {group_type}] "One type"] "Add relation type"]


# Select out all the relationship types that are not currently
# specified for this group type. Note that we use acs_object_types so
# that we can probably indent subtypes. We use acs_rel_types to ensure
# that the passed in group type is acceptable for object_type_one of
# the relationship type. Acceptable means equal to or a child of the
# rel type. If you can find a more efficient way to do this query,
# please let us know! -mbryzek

db_multirow primary_rels select_primary_relations {
    select replace(lpad(' ', (t.type_level - 1) * 4), ' ', '&nbsp;') as indent,
           t.pretty_name, t.rel_type
      from (select t.pretty_name, t.object_type as rel_type, level as type_level
              from acs_object_types t
             where t.object_type not in (select g.rel_type 
                                           from group_type_rels g 
                                          where g.group_type = :group_type)
           connect by prior t.object_type = t.supertype
             start with t.object_type in ('membership_rel', 'composition_rel')) t,
           acs_rel_types rel_type
     where t.rel_type = rel_type.rel_type
       and (rel_type.object_type_one = :group_type 
            or acs_object_type.is_subtype_p(rel_type.object_type_one, :group_type) = 't')
}


set export_vars [ad_export_vars -form {group_type return_url}]

ad_return_template
