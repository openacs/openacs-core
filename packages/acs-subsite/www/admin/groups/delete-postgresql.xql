<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="object_name">      
      <querytext>
      select acs_object__name(:group_id) 
      </querytext>
</fullquery>

 
<fullquery name="select_counts">      
      <querytext>
      
    select (select count(*) from group_element_map where group_id = :group_id) as elements,
           (select count(*) from rel_segments where group_id = :group_id) as segments,
           (select count(*) 
              from rel_constraints cons, rel_segments segs
             where segs.segment_id in (cons.rel_segment,cons.required_rel_segment)
               and segs.group_id = :group_id) as constraints
      

      </querytext>
</fullquery>

 
</queryset>
