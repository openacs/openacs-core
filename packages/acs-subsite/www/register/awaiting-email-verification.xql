<?xml version="1.0"?>
<queryset>

<fullquery name="register_member_state_authorized_set">      
      <querytext>
      update users set 
email_verified_p = 't'
where user_id = :user_id
      </querytext>
</fullquery>

 
</queryset>
