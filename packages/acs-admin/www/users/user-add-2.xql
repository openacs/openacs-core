<?xml version="1.0"?>
<queryset>

<fullquery name="admin_name">      
   <querytext>
      select first_names || ' ' || last_name
      from persons
      where person_id = :admin_user_id
   </querytext>
</fullquery>
 
</queryset>
