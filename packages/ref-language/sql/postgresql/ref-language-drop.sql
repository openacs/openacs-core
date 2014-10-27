-- Drop the ACS Reference Country data
--
-- @author jon@jongriffin.com
-- @cvs-id $Id$

-- drop all associated tables and packages
-- I am not sure this is a good idea since we have no way to register
-- if any other packages are using this data.

-- This will probably fail if their is a child table using this.
-- I can probably make this cleaner also, but ... no time today

drop table language_639_2_codes;

--
-- procedure inline_0/0
--
CREATE OR REPLACE FUNCTION inline_0(
) RETURNS integer AS $$
DECLARE
    rec        acs_reference_repositories%ROWTYPE;
BEGIN
    for rec in select * from acs_reference_repositories where upper(table_name) = 'LANGUAGE_CODES' loop
	 execute 'drop table ' || rec.table_name;
         perform acs_reference__delete(rec.repository_id);
    end loop;
    return 0;
END;
$$ LANGUAGE plpgsql;

select inline_0();
drop function inline_0();

