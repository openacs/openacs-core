--
-- acs-core/sql/acs-core-test-harness.sql
--
-- Test harness for ACS Core's PL/SQL API
--
-- @author Michael Yoon (michael@arsdigita.com)
--
-- @creation-date 2000-08-05
--
-- @cvs-id $Id$
--

create function test_acs_core () returns integer as '
declare
 uid     users.user_id%TYPE;
 tname   varchar;
begin
 raise notice ''Calling acs_user.new() to create user 1'';

 uid :=
  acs_user__new(1,
                ''user'',
                now(),
                null,
                ''127.0.0.1'',                
                ''jane.doe@arsdigita.com'',
                null,
                ''Jane'',
                ''Doe'',
                ''janedoerules'',
                null,
                null,
                null,
                null,
                ''t'',
                null
                );


 tname := acs_object__name(1);

 raise NOTICE ''Calling acs_object.name to get the name of user: %'', tname;

 raise NOTICE ''Calling acs_user.delete to delete user 1'';

 -- PERFORM acs_user__delete(1);

 return NULL;

end;' language 'plpgsql';

create function test_del_user () returns integer as '
declare
begin
  perform acs_user__delete(1);

  return null;

end;' language 'plpgsql';


select test_acs_core ();
select test_del_user ();

drop function test_acs_core ();
drop function test_del_user ();


