--
-- bin/svrmgrl-example.sql
--
-- An example file to create a tablespace with the
-- appropriate permissions.
--
-- @author Richard Li (richardl@arsdigita.com)
-- @creation-date 1 October 2000
-- @cvs-id $Id$

connect internal;

-- substitute a tablespace creation statement appropriate for your
-- installation. this exact statement should almost never be used
-- exactly as is.

create tablespace yourservicename datafile '/ora8/m02/oradata/ora8/yourservicename01.dbf' size 50m autoextend on default storage (pctincrease 1);

create user yourservicename identified by yourservicename default tablespace yourservicename temporary tablespace temp quota unlimited on yourservicename;

grant connect, resource, ctxapp, javasyspriv, query rewrite to yourservicename;

revoke unlimited tablespace from yourservicename;

alter user yourservicename quota unlimited on yourservicename;

-- these are necessary for utPLSQL. you shouldn't grant these on a
-- production system unless absolutely necessary.

grant create public synonym to yourservicename;
grant drop public synonym to yourservicename;
grant execute on dbms_pipe to yourservicename;
grant drop any table to yourservicename;
grant create any table to yourservicename;
