<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_relation_types">      
      <querytext>
    select t.object_type as rel_type, t.pretty_name, t.indent, 
           coalesce(num.number_relationships,0) as number_relationships
      from (select t2.pretty_name, t2.object_type, t2.tree_sortkey as inner_sortkey,
                   repeat('&nbsp;', (tree_level(t2.tree_sortkey) - tree_level(t1.tree_sortkey)) * 4) as indent
              from acs_object_types t1,
		   acs_object_types t2
	     where t2.tree_sortkey between t1.tree_sortkey and tree_right(t1.tree_sortkey)
	       and t1.object_type in ('membership_rel', 'composition_rel')) t left join
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
