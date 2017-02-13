<?xml version="1.0"?>
<queryset>
  <rdbms><type>postgresql</type><version>9.0</version></rdbms>

<fullquery name="select_rel_constraints">      
      <querytext>
      
    select c.constraint_id, c.constraint_name
      from rel_constraints c
           application_group_segments s1, application_group_segments s2
     where s1.segment_id = c.rel_segment
       and s1.package_id = :package_id
       and s2.segment_id = c.required_rel_segment
       and s2.package_id = :package_id
       and acs_permission__permission_p(c.constraint_id, :user_id, 'read')
     order by lower(c.constraint_name)

      </querytext>
</fullquery>

 
</queryset>
