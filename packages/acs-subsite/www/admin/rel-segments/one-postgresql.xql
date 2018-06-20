<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_segment_info">      
      <querytext>
      
         select count(*) as number_elements
           from rel_segment_party_map map
         where map.segment_id = :segment_id
         and acs_permission__permission_p(map.party_id, :user_id, 'read')

      </querytext>
</fullquery>

</queryset>
