<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>
 
<fullquery name="ad_set_client_property.prop_update_dml">      
      <querytext>
        update sec_session_properties
        set property_value = :value,
          secure_p = :secure,
          last_hit = :last_hit 
        where session_id = :session_id and
          module = :module and
          property_name = :name
      </querytext>
</fullquery>

<fullquery name="ad_set_client_property.prop_upsert">      
  <querytext>
    select sec_session_property__upsert(:session_id, :module, :name, :value, :secure, :last_hit) from dual
  </querytext>
</fullquery>
 

<fullquery name="sec_update_user_session_info.update_last_visit">      
      <querytext>

        update users
        set second_to_last_visit = last_visit,
            last_visit = now(),
            n_sessions = n_sessions + 1
        where user_id = :user_id
    
      </querytext>
</fullquery>

 
<fullquery name="populate_secret_tokens_db.insert_random_token">      
      <querytext>

	    insert into secret_tokens(token_id, token, token_timestamp)
	    values(nextval('t_sec_security_token_id_seq'), :random_token, now())
	
      </querytext>
</fullquery>

  
<fullquery name="populate_secret_tokens_cache.get_secret_tokens">      
      <querytext>
      
    select token_id, token
    from secret_tokens,
         (select trunc(random()*(select count(*)-15 from secret_tokens))::integer as first) r
    where token_id >= r.first and r.first+15 > token_id;
	
      </querytext>
</fullquery>

<fullquery name="ad_change_password.password_update">      
      <querytext>
        update users 
        set    password = :new_password, 
               salt = :salt,
               password_changed_date = current_timestamp
        where  user_id = :user_id
      </querytext>
</fullquery>

 
</queryset>
