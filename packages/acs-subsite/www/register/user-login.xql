<?xml version="1.0"?>
<queryset>

<fullquery name="user_login_user_id_from_email">      
      <querytext>
      
    select user_id, member_state, email_verified_p
    from cc_users
    where email = lower(:email)
      </querytext>
</fullquery>

 
</queryset>
