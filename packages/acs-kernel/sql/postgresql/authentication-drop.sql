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



--
-- procedure inline_0/0
--
CREATE OR REPLACE FUNCTION inline_0(

) RETURNS integer AS $$
DECLARE
        row     record;
BEGIN
        for row in select authority_id from auth_authorities
        loop
                perform authority__del(row.authority_id);
        end loop;

        perform acs_object_type__drop_type('authority', 't');

        return 1;
END;
$$ LANGUAGE plpgsql;
select inline_0 ();
drop function inline_0();

drop table auth_authorities cascade;

\i authentication-package-drop.sql
