<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="ad_user_new.user_insert">      
      <querytext>
      
	begin
	    :1 := acs.add_user(
                user_id => :user_id,
		email => :email,
		url => :url,
                authority_id => :authority_id,
		username => :username,
		first_names => :first_names,
		last_name => :last_name,
		screen_name => :screen_name,
		password => :hashed_password,
	        salt => :salt,
                creation_user => :creation_user,
	        creation_ip => :peeraddr,
	        email_verified_p => :email_verified_p,
	        member_state => :member_state
            );
	end;
	
      </querytext>
</fullquery>

<fullquery name="acs_user::delete.permanent_delete">
      <querytext>
          begin
              acs_user.del(
                  user_id => :user_id
              );
          end;
      </querytext>
</fullquery>

<fullquery name="person::delete.delete_person">      
      <querytext>

	    select person.del(:person_id) from dual;
	
      </querytext>
</fullquery>

<fullquery name="user_search">
  <querytext>
      select distinct u.first_names || ' ' || u.last_name || ' (' || u.email || ')' as name, u.user_id
      from   cc_users u
      where  upper(nvl(u.first_names || ' ', '')  ||
             nvl(u.last_name || ' ', '') ||
             u.email || ' ' ||
             nvl(u.screen_name, '')) like upper('%'||:value||'%')
      order  by name
  </querytext>
</fullquery>
 
<fullquery name="acs_user::get_from_user_id_not_cached.select_user_info">      
      <querytext>

          select user_id, 
                 username,
                 authority_id,
                 first_names, 
                 last_name, 
                 first_names || ' ' || last_name as name,
                 email, 
                 url, 
                 screen_name,
                 priv_name,  
                 priv_email,
                 email_verified_p,
                 email_bouncing_p,
                 no_alerts_until,
                 last_visit,
                 second_to_last_visit,
                 n_sessions,
                 password_question,
                 password_answer,
                 password_changed_date,
                 member_state,
                 rel_id, 
                 trunc(sysdate - password_changed_date) as password_age_days
          from   cc_users 
          where  user_id = :user_id

      </querytext>
</fullquery>
 
<fullquery name="acs_user::get_from_username_not_cached.select_user_info">
      <querytext>

          select user_id, 
                 username,
                 authority_id,
                 first_names, 
                 last_name, 
                 first_names || ' ' || last_name as name,
                 email, 
                 url, 
                 screen_name,
                 priv_name,  
                 priv_email,
                 email_verified_p,
                 email_bouncing_p,
                 no_alerts_until,
                 last_visit,
                 second_to_last_visit,
                 n_sessions,
                 password_question,
                 password_answer,
                 password_changed_date,
                 member_state,
                 rel_id, 
                 trunc(sysdate - password_changed_date) as password_age_days
          from   cc_users 
          where  authority_id = :authority_id
          and    upper(username) = upper(:username)

      </querytext>
</fullquery>
 
</queryset>
