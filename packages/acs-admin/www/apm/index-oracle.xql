<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="email_by_user_id">      
      <querytext>
      
    select email  from parties where party_id = :user_id

      </querytext>
</fullquery>

 
</queryset>
