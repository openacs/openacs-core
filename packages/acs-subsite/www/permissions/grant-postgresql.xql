<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="name">      
      <querytext>
      select acs_object__name(:object_id) 
      </querytext>
</fullquery>

<fullquery name="grant">      
      <querytext>
          select acs_permission__grant_permission(:object_id, :party_id, :privilege)
      </querytext>
</fullquery>

<fullquery name="revoke">      
      <querytext>
        select acs_permission__revoke_permission(:object_id, :party_id, :privilege)
      </querytext>
</fullquery>
 
</queryset>
