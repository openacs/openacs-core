<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_rel_segments">      
      <querytext>
      
    select s.segment_id, s.segment_name, s.group_id,
           (select group_name from groups where group_id = s.group_id) as group_name,
           s.rel_type, t.pretty_name as rel_type_pretty_name
      from acs_object_types t, 
           rel_segments s, 
           acs_object_party_privilege_map perm,
           application_group_segments ags
     where perm.object_id = s.segment_id
       and perm.party_id = :user_id
       and perm.privilege = 'read'
       and t.object_type = s.rel_type
       and s.segment_id = ags.segment_id
       and ags.package_id = :package_id
     order by lower(s.segment_name)

      </querytext>
</fullquery>

 
</queryset>
