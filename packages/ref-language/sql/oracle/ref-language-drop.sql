-- Drop the ACS Reference Language data
--
-- @author jon@jongriffin.com
-- @cvs-id $Id$

set serveroutput on

-- drop all associated tables and packages
-- I am not sure this is a good idea since we have no way to register
-- if any other packages are using this data.

-- This will probably fail if their is a child table using this.
-- I can probably make this cleaner also, but ... no time today

drop table language_639_2_codes;

declare
    cursor refsrc_cur is
	 select   table_name,
                  package_name,
                  repository_id
	 from     acs_reference_repositories
	 where upper(table_name) = 'LANGUAGE_CODES';
begin
    for rec in refsrc_cur loop
	 dbms_output.put_line('Dropping ' || rec.table_name);
	 execute immediate 'drop table ' || rec.table_name;
	 if rec.package_name is not null then
	     execute immediate 'drop package ' || rec.package_name;
         end if;
         acs_reference.del(rec.repository_id);
    end loop;
end;
/
show errors

