<?xml version="1.0"?>
<queryset>

<fullquery name="users_state_authorized_or_deleted">      
      <querytext>
      select 
email from cc_users where user_id=:user_id
      </querytext>
</fullquery>

 
<fullquery name="password_answer">      
      <querytext>
      select password_answer from users where user_id = :user_id
      </querytext>
</fullquery>

 
<fullquery name="first_last_name">      
      <querytext>
      select first_names as db_first_names, last_name as db_last_name from cc_users where user_id = $user_id
      </querytext>
</fullquery>

 
</queryset>
