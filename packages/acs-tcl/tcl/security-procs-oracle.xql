<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="sec_populate_secret_tokens_db.insert_random_token">
      <querytext>

	    insert /*+ APPEND */ into secret_tokens(token_id, token, token_timestamp)
	    values(sec_security_token_id_seq.nextval, :random_token, sysdate)

      </querytext>
</fullquery>


<fullquery name="sec_populate_secret_tokens_cache.get_secret_tokens">
      <querytext>

	    select * from (
	    select token_id, token
	    from secret_tokens
	    sample(15)
	    ) where rownum < :num_tokens

      </querytext>
</fullquery>

<fullquery name="ad_set_client_property.prop_update_dml_clob">
      <querytext>
         update sec_session_properties
         set property_value = null,
           property_clob = empty_clob(),
           secure_p = :secure,
           last_hit = :last_hit
         where session_id = :session_id and
           module = :module and
           property_name = :name
         returning property_clob into :1
      </querytext>
</fullquery>

<fullquery name="ad_set_client_property.prop_update_dml">
      <querytext>
         update sec_session_properties
         set property_value = :value,
           property_clob = null,
           secure_p = :secure,
           last_hit = :last_hit
         where session_id = :session_id and
           module = :module and
           property_name = :name
      </querytext>
</fullquery>

</queryset>
