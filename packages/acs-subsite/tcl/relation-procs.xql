<?xml version="1.0"?>
<queryset>

<fullquery name="relation_remove.select_rel_info">      
      <querytext>
      FIX ME OUTER JOIN 
	select s.segment_id, r.object_id_two as party_id, t.package_name
	  from rel_segments s, acs_rels r, acs_object_types t
	 where r.object_id_one = s.group_id(+)
	  and r.rel_type = s.rel_type(+)
	  and r.rel_type = t.object_type
	  and r.rel_id = :rel_id
    
      </querytext>
</fullquery>

 
<fullquery name="relation_remove.relation_delete">      
      <querytext>
-- FIX ME
      select ${package_name}__delete(:rel_id);
      </querytext>
</fullquery>


<fullquery name="relation_remove.select_rel_info">
      <querytext>
      FIX ME OUTER JOIN
	select s.segment_id, r.object_id_two as party_id, t.package_name
	  from rel_segments s, acs_rels r, acs_object_types t
	 where r.object_id_one = s.group_id(+)
	  and r.rel_type = s.rel_type(+)
	  and r.rel_type = t.object_type
	  and r.rel_id = :rel_id

      </querytext>
</fullquery>


<fullquery name="relation_types_valid_to_group_multirow.select_sub_rel_types">
      <querytext>
--      FIX ME DECODE (USE SQL92 CASE)
	select
	    pretty_name, object_type, level, indent,
	    decode(valid_types.rel_type, null, 0, 1) as valid_p
	from
	    (select
	        t.pretty_name, t.object_type, level,
	        replace(lpad(' ', (level - 1) * 4),
	                ' ', '&nbsp;') as indent,
	        rownum as tree_rownum
	     from
	        acs_object_types t
	     connect by
	        prior t.object_type = t.supertype
	     start with
	        t.object_type = :start_with ) types,
	    (select
	        rel_type
	     from
	        rc_valid_rel_types
	     where
	        group_id = :group_id ) valid_types
	where
	    types.object_type = valid_types.rel_type(+)
	order by tree_rownum

      </querytext>
</fullquery>


<fullquery name="relation_required_segments_multirow.select_required_rel_segments">
      <querytext>
      FIX ME OUTER JOIN
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
             rel_segments s,
             rc_segment_dependency_levels dl,
	     groups g, acs_object_types t
	where c.group_id = :group_id
	  and c.rel_type = :rel_type
	  and c.required_rel_segment = map.rel_segment
          and map.required_rel_segment = s.segment_id
          and s.segment_id = dl.segment_id(+)
	  and g.group_id = s.group_id
	  and t.object_type = s.rel_type
        order by coalesce(dl.dependency_level, 0)

      </querytext>
</fullquery>


</queryset>
