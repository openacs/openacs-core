<?xml version="1.0"?>
<queryset>

  <fullquery name="cc_lookup_screen_name_user.user_select_screen_name">      
      <querytext>
      
	select user_id from acs_users_all where lower(screen_name) = lower(:screen_name)
    
      </querytext>
</fullquery>

<fullquery name="cc_lookup_email_user.user_select">
      <querytext>
      
	select user_id from acs_users_all where lower(email) = lower(:email)
    
      </querytext>
</fullquery>

 
<fullquery name="cc_email_from_party.email_from_party">      
      <querytext>

	select email from parties where party_id = :party_id

      </querytext>
</fullquery>

 
<fullquery name="cc_lookup_name_group.group_select">      
      <querytext>
      
	select group_id from groups where group_name = :name
    
      </querytext>
</fullquery>

<fullquery name="oacs::user::get.select_user">
<querytext>
select user_id, screen_name, last_visit, second_to_last_visit,
first_names, last_name, email, first_names || ' ' || last_name as full_name
from users, parties, persons
where 
users.user_id = parties.party_id and
users.user_id = persons.person_id and
user_id= :user_id
</querytext>
</fullquery>

<fullquery name="ad_dbclick_check_dml.double_click_check">      
      <querytext>
      
		
		select 1 as one
		from $table_name
		where $id_column_name = :generated_id
		
	    
      </querytext>
</fullquery>


<fullquery name="validate_zip_code.zip_code_exists">      
      <querytext>
		    select 1
		      from dual
		     where exists (select 1
				     from zip_codes
				    where zip_code like :zip_5)
      </querytext>
</fullquery>


 
</queryset>
