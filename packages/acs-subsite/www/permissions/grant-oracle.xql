<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="name">      
      <querytext>
      select acs_object.name(:object_id) from dual
      </querytext>
</fullquery>

<fullquery name="select_privileges_hierarchy">      
      <querytext>
          select privilege, child_privilege
          from acs_privilege_hierarchy
      </querytext>
</fullquery>

<fullquery name="grant">      
      <querytext>
          select acs_permission.grant_permission(:object_id, :party_id, :privilege)
      </querytext>
</fullquery>

<fullquery name="revoke">      
      <querytext>
        select acs_permission.revoke_permission(:object_id, :party_id, :privilege)
      </querytext>
</fullquery>
 
</queryset>
