<?xml version="1.0"?>


<queryset>
    <rdbms>
      <type>postgresql</type>
      <version>7.1</version>
    </rdbms>

  <fullquery name="populate_secret_tokens_db.insert_random_token">
    <querytext>
    insert into secret_tokens(token_id, token, timestamp)
                      values (sec_security_token_id_seq.nextval, :random_token, now())
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
