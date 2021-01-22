<?xml version="1.0"?>
<queryset>

<fullquery name="admin_name">      
   <querytext>
      select first_names || ' ' || last_name
      from persons
      where person_id = :admin_user_id
   </querytext>
</fullquery>

<fullquery name="double_click">      
   <querytext>
      select count(user_id) from users where user_id = :user_id
   </querytext>
</fullquery>
 
</queryset>
