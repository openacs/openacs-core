<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_relation_types">      
      <querytext>
    select t.object_type as rel_type, t.pretty_name, t.indent, 
           coalesce(num.number_relationships,0) as number_relationships
      from (select t.pretty_name, t.object_type, tree_sortkey as inner_sortkey,
                   lpad('&nbsp;', (tree_level(tree_sortkey) - 1) * 4) as indent
              from acs_object_types t
	     where (t.tree_sortkey like (select tree_sortkey || '%' from acs_object_types
					where object_type='membership_rel')
		or t.tree_sortkey like (select tree_sortkey || '%' from acs_object_types
					where object_type='composition_rel'))
             order by lower(t.pretty_name)) t left join
           (select r.rel_type, count(*) as number_relationships
              from acs_objects o, acs_rel_types r, 
                   app_group_distinct_rel_map m
             where r.rel_type = o.object_type
               and o.object_id = m.rel_id
               and m.package_id = :package_id
             group by r.rel_type) num
	on (t.object_type = num.rel_type)
    order by t.inner_sortkey

      </querytext>
</fullquery>

 
</queryset>
