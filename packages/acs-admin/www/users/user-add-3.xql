<?xml version="1.0"?>
<queryset>

  <fullquery name="get_admin_email">      
    <querytext>
      select email from parties where party_id = :admin_user_id
    </querytext>
  </fullquery>
 
</queryset>
