<?xml version="1.0"?>
<queryset>

<fullquery name="constraints_select">      
      <querytext>
      
    select c.constraint_id, c.constraint_name, c.rel_side
      from rel_constraints c
     where c.rel_segment = :segment_id

      </querytext>
</fullquery>
 
</queryset>
