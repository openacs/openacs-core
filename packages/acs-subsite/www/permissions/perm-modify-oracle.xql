<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="remove">      
      <querytext>
      
          begin
              acs_permission.revoke_permission(
                  object_id => :object_id, 
                  grantee_id => :party_id,
                  privilege => :privilege
              );
          end;
  
      </querytext>
</fullquery>


<fullquery name="add">      
      <querytext>
      
          begin
              acs_permission.grant_permission(
                  object_id => :object_id, 
                  grantee_id => :party_id,
                  privilege => :privilege
              );
          end;
  
      </querytext>
</fullquery>


</queryset>


