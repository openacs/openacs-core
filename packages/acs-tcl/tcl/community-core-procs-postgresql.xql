<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="ad_user_new.user_insert">      
      <querytext>

	    select acs__add_user(
                         :user_id,
                         'user',
                         now(),
                         null,
	                 :peeraddr,
			 :email,
			 :url,
			 :first_names,
			 :last_name,
			 :hashed_password,
	                 :salt,
	                 :password_question,
	                 :password_answer,
                         null,
	                 :email_verified_p,
	                 :member_state);
	
      </querytext>
</fullquery>

<fullquery name="person::delete.delete_person">      
      <querytext>

	    select person__delete(:person_id);
	
      </querytext>
</fullquery>

<fullquery name="user_search">
  <querytext>
      select distinct u.first_names || ' ' || u.last_name || ' (' || u.email || ')' as name, u.user_id
      from   cc_users u
      where  upper(coalesce(u.first_names || ' ', '')  ||
             coalesce(u.last_name || ' ', '') ||
             u.email || ' ' ||
             coalesce(u.screen_name, '')) like upper('%'||:value||'%')
      order  by name
  </querytext>
</fullquery>

</queryset>
