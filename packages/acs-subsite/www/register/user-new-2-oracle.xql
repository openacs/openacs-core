<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="user_new_2_rowid_for_email">      
      <querytext>
      select rowid from users where user_id = :user_id
      </querytext>
</fullquery>

 
</queryset>
