<?xml version="1.0"?>
<queryset>

<fullquery name="constraints_select">      
      <querytext>
      
    select c.constraint_id, c.constraint_name, c.rel_side
      from rel_constraints c
     where c.rel_segment = :segment_id

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
