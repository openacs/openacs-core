<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="sec_update_user_session_info.update_last_visit">      
      <querytext>

        update users
        set second_to_last_visit = last_visit,
            last_visit = now(),
            n_sessions = n_sessions + 1
        where user_id = :user_id
    
      </querytext>
</fullquery>

 
<fullquery name="ad_maybe_redirect_for_registration.sql_test_1">      
      <querytext>
      select test_sql('select 1  where 1=[DoubleApos $value]') 
      </querytext>
</fullquery>

 
<fullquery name="ad_maybe_redirect_for_registration.sql_test_2">      
      <querytext>
      select test_sql('select 1  where 1=[DoubleApos "'$value'"]') 
      </querytext>
</fullquery>

 
<fullquery name="populate_secret_tokens_db.insert_random_token">      
      <querytext>

	    insert into secret_tokens(token_id, token, token_timestamp)
	    values(sec_security_token_id_seq.nextval, :random_token, now())
	
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

</queryset>
