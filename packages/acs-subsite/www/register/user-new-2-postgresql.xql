<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="user_new_2_rowid_for_email">      
      <querytext>
      select oid from users where user_id = :user_id
      </querytext>
</fullquery>

 
</queryset>
