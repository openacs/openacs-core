<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="remove">      
      <querytext>
      
          select acs_permission__revoke_permission(:object_id, :party_id, :privilege) 
  
      </querytext>
</fullquery>


<fullquery name="add">      
      <querytext>
      
          select acs_permission__grant_permission(:object_id, :party_id, :privilege) 
  
      </querytext>
</fullquery>




 
</queryset>
