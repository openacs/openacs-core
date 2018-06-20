<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_rel_segments">      
      <querytext>
      
    select s.segment_id, s.segment_name, s.group_id,
           (select group_name from groups where group_id = s.group_id) as group_name,
           s.rel_type, t.pretty_name as rel_type_pretty_name
      from acs_object_types t, 
           rel_segments s, 
           application_group_segments ags
     where acs_permission__permission_p(s.segment_id, :user_id, 'read')
       and t.object_type = s.rel_type
       and s.segment_id = ags.segment_id
       and ags.package_id = :package_id
     order by lower(s.segment_name)

      </querytext>
</fullquery>

 
</queryset>
