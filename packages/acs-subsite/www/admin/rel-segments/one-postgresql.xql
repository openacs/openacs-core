<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_segment_properties">      
      <querytext>
      
    select s.segment_id, s.segment_name, s.group_id, acs_object__name(s.group_id) as group_name,
           s.rel_type, acs_object_type__pretty_name(r.rel_type) as rel_type_pretty_name,
           acs_rel_type__role_pretty_plural(r.role_two) as role_pretty_plural
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
         and acs_permission__permission_p(map.party_id, :user_id, 'read')

      </querytext>
</fullquery>


</queryset>
