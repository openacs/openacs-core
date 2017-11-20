<?xml version="1.0"?>
<queryset>

<fullquery name="sec_update_user_session_info.update_last_visit">      
      <querytext>

        update users
        set second_to_last_visit = last_visit,
            last_visit = current_timestamp,
            n_sessions = n_sessions + 1
        where user_id = :user_id
    
      </querytext>
</fullquery>

  
<fullquery name="sec_sweep_sessions.sessions_sweep">      
      <querytext>
      
	delete from sec_session_properties
	where last_hit < :expires
    
      </querytext>
</fullquery>

 
<fullquery name="ad_check_password.password_select">      
      <querytext>
      select password, salt from users where user_id = :user_id
      </querytext>
</fullquery>

 
<fullquery name="sec_lookup_property.property_lookup_sec">      
      <querytext>
      
	    select property_value, secure_p
	    from sec_session_properties
	    where session_id = :id
	    and module = :module
	    and property_name = :name
	
      </querytext>
</fullquery>

<fullquery name="sec_get_token.get_token">      
      <querytext>
      select token from secret_tokens where token_id = :token_id
      </querytext>
</fullquery>
 
<fullquery name="ad_set_client_property.prop_insert_dml">      
      <querytext>
	insert into sec_session_properties
	  (session_id, module, property_name, secure_p, last_hit)
	select :session_id, :module, :name, :secure, :last_hit
        from dual
        where not exists (select 1
                          from sec_session_properties
                          where session_id = :session_id and
                          module = :module and
                          property_name = :name)
      </querytext>
</fullquery>

<fullquery name="sec_lookup_property.update_last_hit_dml">
      <querytext>
	update sec_session_properties
	   set last_hit = :new_last_hit
	 where session_id = :id and
               property_name = :name
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
