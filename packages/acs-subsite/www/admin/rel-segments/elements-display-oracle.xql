<?xml version="1.0"?>
<!-- used in elements-display.adp ... ugh -->
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>


<fullquery name="elements_select">
<querytext>
    select acs_object.name(map.party_id) as name, map.rel_id, 
           decode(map.container_id, :group_id, 1, 0) as direct_p,
           acs_object.name(map.container_id) as container_name
      from rel_segment_party_map map
     where acs_permission.permission_p(map.party_id, :user_id, 'read') = 't'
       and map.segment_id = :segment_id
     order by lower(name)
</querytext>
</fullquery>
 
</queryset>