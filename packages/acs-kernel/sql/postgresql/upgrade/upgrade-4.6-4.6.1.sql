-- acs-kernel/sql/postgresql/upgrade/upgrade-4.6-4.6.1.sql
--
-- @author Jeff Davis (davis@xarg.net)
-- @creation-date 2002-12-17
-- @cvs-id $Id$


-- declaring this function isstrict,iscachable can make a significant
-- performance difference since this is used in some potentially
-- expensive queries

create or replace function acs__magic_object_id (varchar)
returns integer as '
declare
  magic_object_id__name                   alias for $1;  
  magic_object_id__object_id              acs_objects.object_id%TYPE;
begin
    select object_id
    into magic_object_id__object_id
    from acs_magic_objects
    where name = magic_object_id__name;

    return magic_object_id__object_id;
   
end;' language 'plpgsql' with(isstrict,iscachable);
