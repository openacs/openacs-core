<?xml version="1.0"?>
<queryset>

<fullquery name="select_segment_id">      
      <querytext>
      
	select s.segment_id
	  from rel_segments s
	 where s.group_id = :group_id
	   and s.rel_type = :rel_type
    
      </querytext>
</fullquery>

 
</queryset>
