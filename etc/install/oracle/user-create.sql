create user :oracle_user identified by :oracle_password default tablespace :oracle_user temporary tablespace temp quota unlimited on :oracle_user;
grant connect, resource, ctxapp, javasyspriv, query rewrite to :oracle_user;
revoke unlimited tablespace from :oracle_user;
alter user :oracle_user quota unlimited on :oracle_user;
