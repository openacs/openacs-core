<?xml version="1.0"?>
<queryset>
  <fullquery name="acs.acs-tcl.tcl.security-procs.populate_secret_tokens_db.insert_random_token">
    <querytext>
    insert into secret_tokens(token_id, token, timestamp)
                      values (sec_security_token_id_seq.nextval, :random_token, now())
    </querytext>
    <rdbms>
      <type>postgresql</type>
      <version>7.1</version>
    </rdbms>
  </fullquery>
</queryset>
