-- Drop the ACS Reference packages
--
-- @author jon@jongriffin.com
-- @cvs-id $Id$

set serveroutput on

-- drop all associated tables and packages
-- ordered by repository_id for dependencies.

declare
    cursor refsrc_cur is
	 select   table_name,
                  package_name,
                  repository_id
	 from     acs_reference_repositories
         order by repository_id desc;
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

-- drop privileges
begin
    acs_privilege.remove_child('create','acs_reference_create');
    acs_privilege.remove_child('write', 'acs_reference_write');
    acs_privilege.remove_child('read',  'acs_reference_read');
    acs_privilege.remove_child('delete','acs_reference_delete');

    acs_privilege.drop_privilege('acs_reference_create');
    acs_privilege.drop_privilege('acs_reference_write');
    acs_privilege.drop_privilege('acs_reference_read');
    acs_privilege.drop_privilege('acs_reference_delete');
end;
/
show errors

-- drop the object

begin
    acs_object_type.drop_type('acs_reference_repository','t');
end;
/
show errors
  
drop package acs_reference;
drop table   acs_reference_repositories;

