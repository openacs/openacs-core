<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="add_user">      
      <querytext>

            select acs_permission__grant_permission(:object_id, :one_user_id, 'read')

      </querytext>
</fullquery>


 
</queryset>
