<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="party_info">      
      <querytext>
      
    select acs_object__name(:party_id) as party_name,
           object_type as party_type
      from acs_objects
     where object_id = :party_id

      </querytext>
</fullquery>

 
</queryset>
