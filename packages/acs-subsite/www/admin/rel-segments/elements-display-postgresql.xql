<?xml version="1.0"?>
<!-- used in elements-display.adp ... ugh -->
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="elements_select">
<querytext>
    select acs_object__name(map.party_id) as name, map.rel_id, 
           case when map.container_id = :group_id then 1 else 0 end as direct_p,
           acs_object__name(map.container_id) as container_name
      from rel_segment_party_map map
     where acs_permission__permission_p(map.party_id, :user_id, 'read') = 't'
       and map.segment_id = :segment_id
     order by name
</querytext>
</fullquery>

</queryset>