<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="relations_query">      
      <querytext>

    select g.rel_type, g.group_rel_id,
           acs_object_type__pretty_name(g.rel_type) as rel_type_pretty_name,
           s.segment_id, s.segment_name, 
           acs_rel_type__role_pretty_plural(rel_types.role_two) as role_pretty_plural,
           acs_rel_type__role_pretty_name(rel_types.role_two) as role_pretty_name,
           rels.num_rels,
           case when valid_types.group_id = null then 0 else 1 end as rel_type_valid_p
      from group_rels g
	     left outer join rel_segments s using (group_id, rel_type)
	     left outer join rc_valid_rel_types valid_types using (group_id, rel_type)
	     left outer join
	       (select rel_type, count(*) as num_rels
	          from group_component_map
		 where group_id = :group_id
		   and group_id = container_id
	      group by rel_type
	      UNION ALL
	        select rel_type, count(*) as num_rels
		  from group_approved_member_map
		 where group_id = :group_id
		   and group_id = container_id
	      group by rel_type) rels using (rel_type),
	   acs_rel_types rel_types
     where g.rel_type = rel_types.rel_type
       and g.group_id = :group_id
  order by lower(g.rel_type)

      </querytext>
</fullquery>

 
</queryset>
