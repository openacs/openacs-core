<?xml version="1.0"?>
<queryset>

<fullquery name="select_segments">      
      <querytext>
      
    select s.segment_name, s.segment_id
      from application_group_segments s
     where s.segment_id <> :rel_segment
       and s.package_id = :package_id

     order by lower(s.segment_name)

      </querytext>
</fullquery>

 
</queryset>
