<?xml version="1.0"?>
<queryset>

<fullquery name="register_email_user_update">      
      <querytext>
      update users 
                        set email_verified_p = 't'
                        where user_id = :user_id
      </querytext>
</fullquery>

 
<fullquery name="register_email_confirm_update3">      
      <querytext>
      update users
                        set email_verified_p = 't'
                        where user_id = :user_id
      </querytext>
</fullquery>

 
</queryset>
