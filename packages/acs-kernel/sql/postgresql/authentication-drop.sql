--
-- acs-kernel/sql/postgresql/authentication-drop.sql
--
-- The OpenACS core authentication system drop script.
--
-- @author Peter Marklund (peter@collaboraid.biz)
--
-- @creation-date 20003-08-21
--
-- @cvs-id $Id$
--

create function inline_0 ()
returns integer as '
declare
        row     record;
begin
        for row in select authority_id from auth_authorities
        loop
                perform authority__del(row.authority_id);
        end loop;

        perform acs_object_type__drop_type(''authority'', ''t'');

        return 1;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0();

drop table auth_authorities cascade;

\i authentication-package-drop.sql
