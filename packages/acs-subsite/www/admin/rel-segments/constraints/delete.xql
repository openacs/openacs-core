<?xml version="1.0"?>
<queryset>

<fullquery name="select_constraint_props">      
      <querytext>
      
    select c.constraint_name, s.segment_name
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
