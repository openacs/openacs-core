-- packages/acs-reference/sql/common/timezone-drop.sql
--
-- Drop the timezone package
--
-- @author  jon@jongriffin.com
-- @created 2000-12-04
-- @cvs-id  $Id$

create function inline_0() returns integer as '
declare
    rec        acs_reference_repositories%ROWTYPE;
begin
    for rec in select * from acs_reference_repositories where upper(table_name) = ''TIMEZONES'' loop
	 execute ''drop table '' || rec.table_name;
         perform acs_reference__delete(rec.repository_id);
    end loop;
    return 0;
end;' language 'plpgsql';

select inline_0();
drop function inline_0();

drop sequence timezone_seq;
drop table    timezone_rules;

drop function rdbms_date(varchar);
drop function timezone__new (varchar, varchar);
drop function timezone__delete (integer);
drop function timezone__get_id (varchar);
drop function timezone__add_rule (varchar, varchar, integer, varchar, varchar, varchar, varchar, varchar);
drop function timezone__convert_to_utc (integer, varchar);
drop function timezone__get_offset (integer, timestamptz);
drop function timezone__get_rawoffset (integer, timestamptz);
drop function timezone__get_abbrev (integer, timestamptz);
drop function timezone__get_date (integer, timestamptz, varchar, boolean);
drop function timezone__isdst_p (integer, timestamptz);
drop function timezone__get_zone_offset (integer, integer, timestamptz);
