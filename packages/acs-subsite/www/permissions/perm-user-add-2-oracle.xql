<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="add_user">      
      <querytext>

          begin
              acs_permission.grant_permission(
                  object_id => :object_id, 
                  grantee_id => :one_user_id,
                  privilege => 'read'
              );
          end;

      </querytext>
</fullquery>


 
</queryset>
