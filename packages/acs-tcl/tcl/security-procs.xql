<?xml version="1.0"?>
<queryset>

<fullquery name="sec_sweep_sessions.sessions_sweep">      
      <querytext>
      
	delete from sec_session_properties
	where  :current_time - last_hit > :property_life
    
      </querytext>
</fullquery>

 
<fullquery name="ad_check_password.password_select">      
      <querytext>
      select password, salt from users where user_id = :user_id
      </querytext>
</fullquery>

 
<fullquery name="ad_change_password.password_update">      
      <querytext>
      update users set password = :new_password, salt = :salt where user_id = :user_id
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

 
<fullquery name="ad_set_client_property.prop_delete_dml">      
      <querytext>
      
		delete from sec_session_properties
		where  session_id = :session_id
		and    module = :module
		and    property_name = :name
	    
      </querytext>
</fullquery>

 
<fullquery name="ad_set_client_property.prop_insert_dml">      
      <querytext>
      
		insert into sec_session_properties
		(session_id, module, property_name, property_value, secure_p, last_hit)
		values ( :session_id, :module, :name, :value, :secure, :last_hit )
	    
      </querytext>
</fullquery>

 
<fullquery name="sec_get_token.get_token">      
      <querytext>
      select token from secret_tokens
      where token_id = :token_id
      </querytext>
</fullquery>

 
</queryset>
