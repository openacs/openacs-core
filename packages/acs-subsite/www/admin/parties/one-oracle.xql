<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="party_info">      
      <querytext>
      
    select acs_object.name(:party_id) as party_name,
           object_type as party_type
      from acs_objects
     where object_id = :party_id

      </querytext>
</fullquery>

 
</queryset>
