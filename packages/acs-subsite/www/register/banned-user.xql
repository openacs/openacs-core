<?xml version="1.0"?>
<queryset>

<fullquery name="register_banned_member_state">      
      <querytext>
      
    select member_state from cc_users 
    where user_id = :user_id 
      </querytext>
</fullquery>

 
</queryset>
