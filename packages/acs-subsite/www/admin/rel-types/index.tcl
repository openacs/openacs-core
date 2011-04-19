# /packages/mbryzek-subsite/www/admin/rel-types/index.tcl

ad_page_contract {

    Shows list of all defined relationship types, excluding the parent
    type "relationship"

    @author mbryzek@arsdigita.com
    @creation-date Sun Dec 10 17:10:56 2000
    @cvs-id $Id$

} {
} -properties {
    context:onevalue
    rel_types:multirow
}

set context [list [_ acs-subsite.Relationship_Types]]

set package_id [ad_conn package_id]

# Select out all relationship types, excluding the parent type names 'relationship'
# Count up the number of relations that exists for each type.
db_multirow rel_types select_relation_types {
    select t.object_type as rel_type, t.pretty_name, t.indent, 
           nvl(num.number_relationships,0) as number_relationships
      from (select t.pretty_name, t.object_type, rownum as inner_rownum,
                   replace(lpad(' ', (level - 1) * 4), ' ', '&nbsp;') as indent
              from acs_object_types t
           connect by prior t.object_type = t.supertype
             start with t.object_type in ('membership_rel','composition_rel')
             order by lower(t.pretty_name)) t,
           (select r.rel_type, count(*) as number_relationships
              from acs_objects o, acs_rel_types r, 
                   app_group_distinct_rel_map m
             where r.rel_type = o.object_type
               and o.object_id = m.rel_id
               and m.package_id = :package_id
             group by r.rel_type) num
     where t.object_type = num.rel_type(+)
    order by t.inner_rownum
}

ad_return_template
