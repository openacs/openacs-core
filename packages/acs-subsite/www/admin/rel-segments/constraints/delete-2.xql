<?xml version="1.0"?>
<queryset>

<fullquery name="select_segment_id">      
      <querytext>
      
	    select c.rel_segment as segment_id from rel_constraints c where c.constraint_id = :constraint_id
	
      </querytext>
</fullquery>

 
<fullquery name="select_constraint_props">      
      <querytext>
      
	select 1
        from rel_constraints c, application_group_segments s,
             application_group_segments s2
	where c.rel_segment = s.segment_id
          and c.constraint_id = :constraint_id
          and s.package_id = :package_id
          and s2.segment_id = c.required_rel_segment
          and s2.package_id = :package_id
    
      </querytext>
</fullquery>

 
</queryset>
