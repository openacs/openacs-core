-- packages/acs-reference/sql/postgresql/acs-reference-data.sql
--
-- Drop the ACS Reference packages
--
-- @author jon@jongriffin.com
-- @created 2001-07-16
--
-- @cvs-id $Id$
--

set serveroutput on

-- drop all associated tables and packages

declare
    cursor refsrc_cur is
	 select   table_name,
                  package_name
	 from     acs_reference_repositories
         order by creation_date desc;
begin
    for rec in refsrc_cur loop
	 dbms_output.put_line('Dropping ' || rec.table_name);
	 execute immediate 'drop table ' || rec.table_name;
	 if rec.package_name is not null then
	     execute immediate 'drop package ' || rec.package_name;
         end if;
    end loop;
end;
/
show errors

begin
    acs_object_type.drop_type('acs_reference_repository','t');
end;
/
show errors
  
drop package acs_reference_repository;
drop table   acs_reference_repositories;

