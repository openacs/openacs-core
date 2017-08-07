<?xml version="1.0"?>
<queryset>

<fullquery name="relation_remove.select_rel_info_rm">
      <querytext>

	select s.segment_id, r.object_id_two as party_id, t.package_name
	  from acs_rels r
	         left outer join rel_segments s
		   on (r.object_id_one = s.group_id and r.rel_type = s.rel_type), 
	       acs_object_types t
	 where r.rel_type = t.object_type
	  and r.rel_id = :rel_id
    
      </querytext>
</fullquery>

<fullquery name="relation_segment_has_dependent.select_rel_info">      
      <querytext>
	    select s.segment_id, r.object_id_two as party_id
  	      from rel_segments s, acs_rels r
	     where r.object_id_one = s.group_id
	       and r.rel_type = s.rel_type
	       and r.rel_id = :rel_id
      </querytext>
</fullquery>


<fullquery name="relation_required_segments_multirow.select_required_rel_segments">      
      <querytext>

	select distinct s.segment_id, s.group_id, s.rel_type,
	       g.group_name, g.join_policy, t.pretty_name as rel_type_pretty_name,
               coalesce(dl.dependency_level, 0)
	from rc_all_constraints c, 
             (select rel_segment, required_rel_segment
              from rc_segment_required_seg_map
	      where rel_side = 'two'
	      UNION ALL
	      select segment_id, segment_id
	      from rel_segments) map,
             rel_segments s left outer join rc_segment_dependency_levels dl using (segment_id),
	     groups g, acs_object_types t
	where c.group_id = :group_id
	  and c.rel_type = :rel_type
	  and c.required_rel_segment = map.rel_segment
          and map.required_rel_segment = s.segment_id
	  and g.group_id = s.group_id
	  and t.object_type = s.rel_type
        order by coalesce(dl.dependency_level, 0)
    
      </querytext>
</fullquery>

 
<fullquery name="relation::get_id.select_rel_id">      
      <querytext>

          select rel_id 
          from   acs_rels 
          where  rel_type = :rel_type
          and    object_id_one = :object_id_one
          and    object_id_two = :object_id_two

      </querytext>
</fullquery>

<fullquery name="relation::get_object_one.select_object_one">      
      <querytext>

          select object_id_one 
          from   acs_rels 
          where  rel_type = :rel_type
          and    object_id_two = :object_id_two

      </querytext>
</fullquery>

<fullquery name="relation::get_object_two.select_object_two">      
      <querytext>

          select object_id_two 
          from   acs_rels 
          where  rel_type = :rel_type
          and    object_id_one = :object_id_one

      </querytext>
</fullquery>

</queryset>
