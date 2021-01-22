<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_segment_properties">      
      <querytext>
      
    select s.segment_id, s.segment_name, s.group_id, acs_object.name(s.group_id) as group_name,
           s.rel_type, acs_object_type.pretty_name(r.rel_type) as rel_type_pretty_name,
           acs_rel_type.role_pretty_plural(r.role_two) as role_pretty_plural
      from rel_segments s, acs_rel_types r
     where s.segment_id = :segment_id
       and s.rel_type = r.rel_type

      </querytext>
</fullquery>

<fullquery name="select_segment_info">      
      <querytext>
      
         select count(*) as number_elements
           from rel_segment_party_map map
         where map.segment_id = :segment_id
           and exists (select 1
                       from acs_object_party_privilege_map perm
                       where perm.object_id = map.party_id
                         and perm.party_id = :user_id
                         and perm.privilege = 'read')

      </querytext>
</fullquery>

 
</queryset>
