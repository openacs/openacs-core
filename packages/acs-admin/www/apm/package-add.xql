<?xml version="1.0"?>
<queryset>

<fullquery name="apm_get_name">      
      <querytext>
       
    select first_names || ' ' || last_name as user_name, email from cc_users where user_id = :user_id

      </querytext>
</fullquery>

 
</queryset>
