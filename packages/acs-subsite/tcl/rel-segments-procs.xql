<?xml version="1.0"?>
<queryset>

<fullquery name="rel_segments_delete.select_dependant_constraints">      
      <querytext>
      
	select c.constraint_id
	  from rel_constraints c
	 where c.required_rel_segment = :segment_id
    
      </querytext>
</fullquery>

 
</queryset>
