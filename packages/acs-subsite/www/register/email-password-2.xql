<?xml version="1.0"?>
<queryset>

<fullquery name="users_state_authorized_or_deleted">      
      <querytext>
      select 
email from cc_users where user_id=:user_id
-- and user_state in ('authorized','deleted')
      </querytext>
</fullquery>

 
<fullquery name="password_answer">      
      <querytext>
      select password_answer from users where user_id = :user_id
      </querytext>
</fullquery>

 
<fullquery name="first_last_name">      
      <querytext>
      select first_names db_first_names, last_name db_last_name from cc_users where user_id = $user_id
      </querytext>
</fullquery>

 
</queryset>
