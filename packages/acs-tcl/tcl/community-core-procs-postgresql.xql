<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="acs_user::delete.permanent_delete">
      <querytext>
          select acs__remove_user(:user_id);
      </querytext>
</fullquery>

<fullquery name="person::delete.delete_person">      
      <querytext>

            select person__delete(:person_id);
        
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
                 to_char(last_visit, 'YYYY-MM-DD HH24:MI:SS') as last_visit_ansi, 
                 second_to_last_visit,
                 to_char(second_to_last_visit, 'YYYY-MM-DD HH24:MI:SS') as second_to_last_visit_ansi, 
                 n_sessions,
                 password_question,
                 password_answer,
                 password_changed_date,
                 member_state,
                 rel_id, 
                 trunc(date_part('epoch', age(password_changed_date))/(60*60*24)) as password_age_days,
                 creation_date,
                 creation_ip
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
                 to_char(last_visit, 'YYYY-MM-DD HH24:MI:SS') as last_visit_ansi, 
                 second_to_last_visit,
                 to_char(second_to_last_visit, 'YYYY-MM-DD HH24:MI:SS') as second_to_last_visit_ansi, 
                 n_sessions,
                 password_question,
                 password_answer,
                 password_changed_date,
                 member_state,
                 rel_id, 
                 trunc(date_part('epoch', age(password_changed_date))/(60*60*24)) as password_age_days,
                 creation_date,
                 creation_ip
          from   cc_users 
          where  authority_id = :authority_id
          and    lower(username) = lower(:username)

      </querytext>
</fullquery>
 
</queryset>
