<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_group_types">      
      <querytext>

    select t.object_type as group_type, t.pretty_plural, 
	   coalesce(num.number_groups,0) as number_groups, 
	   repeat('&nbsp;', t.type_level * 4) as indent
      from (select t2.object_type, t2.pretty_plural, t2.tree_sortkey,
		   tree_level(t2.tree_sortkey) - tree_level(t1.tree_sortkey) as type_level
	      from acs_object_types t1,
		   acs_object_types t2
	     where t1.object_type = 'group'
	       and t2.tree_sortkey between t1.tree_sortkey and tree_right(t1.tree_sortkey)) t
                   left outer join
	   (select object_type, count(group_id) as number_groups from 
  	     (select distinct o.object_type, g.group_id   
                from groups g, acs_objects o,  
                     application_group_element_map app_group
               where acs_permission__permission_p(g.group_id, :user_id, 'read')
                 and o.object_id = g.group_id
                 and ((app_group.package_id = :package_id and app_group.element_id = g.group_id)
		 -- the or-clause below is just needed for "Registered Users" (-2)
		 -- which is an application group for e.g. a subsite,
		 -- but not mapped to it via application_group_element_map
	         or  (o.object_id = -2)
	     )) counts
             group by object_type) num
             using (object_type)
     order by t.tree_sortkey

      </querytext>
</fullquery>

 
</queryset>
