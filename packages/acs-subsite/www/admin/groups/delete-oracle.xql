<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="object_name">      
      <querytext>
      select acs_object.name(:group_id) from dual
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
      from dual

      </querytext>
</fullquery>

 
</queryset>
