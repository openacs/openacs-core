<?xml version="1.0"?>
<queryset>

<fullquery name="select_segment_info">      
      <querytext>
      
    select s.segment_name 
      from rel_segments s
     where s.segment_id = :segment_id

      </querytext>
</fullquery>

 
</queryset>
