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
</queryset>
