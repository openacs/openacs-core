-- packages/acs-reference/sql/postgresql/acs-reference-data.sql
--
-- Drop the ACS Reference packages
--
-- @author jon@jongriffin.com
-- @dropd 2001-07-16
--
-- @cvs-id $Id$
--

-- drop all associated tables and functions

-- DRB: in PG we could do this dynamically as JonG has done in Oracle.  The
-- proc name can easily be picked up from pg_proc since we use unique package
-- keys as prefaces.   The params can be picked up as well but I don't know
-- how off the top of my head.  It would be a nice to write a general function
-- to do this in both Oracle and PG - "drop_package_functions(package_key)".

    
select acs_privilege__remove_child('create','acs_reference_create');
select acs_privilege__remove_child('write', 'acs_reference_write');
select acs_privilege__remove_child('read',  'acs_reference_read');
select acs_privilege__remove_child('delete','acs_reference_delete');

select acs_privilege__drop_privilege('acs_reference_create');
select acs_privilege__drop_privilege('acs_reference_write');
select acs_privilege__drop_privilege('acs_reference_read');
select acs_privilege__drop_privilege('acs_reference_delete');

select acs_object__delete(repository_id)
from acs_reference_repositories;

select acs_object_type__drop_type ('acs_reference_repository', 't');

drop function acs_reference__new (varchar,timestamptz, varchar,varchar,timestamptz);
drop function acs_reference__new (integer,varchar,boolean,varchar,timestamptz,
varchar,varchar,timestamptz,timestamptz,integer,integer,varchar,varchar,
integer,varchar,integer);
drop function acs_reference__delete (integer);
drop function acs_reference__is_expired_p (integer);
drop table   acs_reference_repositories;

