-- packages/acs-reference/sql/postgresql/acs-reference-create.sql
--
-- @author jon@jongriffin.com
-- @creation-date 2001-07-16
--
-- @cvs-id $Id$

-- setup the basic admin privileges

create function inline_0 ()
returns integer as '
begin
    PERFORM acs_privilege__create_privilege(''acs_reference_create'');
    PERFORM acs_privilege__create_privilege(''acs_reference_write'');
    PERFORM acs_privilege__create_privilege(''acs_reference_read'');
    PERFORM acs_privilege__create_privilege(''acs_reference_delete'');
    
    PERFORM acs_privilege__add_child(''create'',''acs_reference_create'');
    PERFORM acs_privilege__add_child(''write'', ''acs_reference_write'');
    PERFORM acs_privilege__add_child(''read'',  ''acs_reference_read'');
    PERFORM acs_privilege__add_child(''delete'',''acs_reference_delete'');
    
    return 0;
end;' language 'plpgsql';


-- Create the basic object type used to represent a reference database
select acs_object_type__create_type (
        'acs_object',
        'acs_reference_repository',
        'ACS Reference Repository',
        'ACS Reference Repositories', 
        'acs_reference_repositories',
        'repository_id',
        'f',
	null,
	'acs_object.default_name'
);

-- A table to store metadata for each reference database
-- add functions to do exports and imports to selected tables.

create table acs_reference_repositories (
    repository_id	integer
			constraint arr_repository_id_fk references acs_objects (object_id)
			constraint arr_repository_id_pk primary key,
    -- what is the table name we are monitoring
    table_name		varchar(100)  
			constraint arr_table_name_nn not null
			constraint arr_table_name_uq unique,
    -- is this external or internal data
    internal_data_p     char(1)       
			constraint arr_internal_data_p_ck
        		check (internal_data_p in ('t','f')),
    -- Does this source include pl/sql package?
    package_name	varchar(100)
			constraint arr_package_name_uq unique,
    -- last updated
    last_update		timestamp,
    -- where is this data from
    source		varchar(1000),
    source_url		varchar(255),
    -- should default to today
    effective_date	timestamp -- default sysdate
    expiry_date		timestamp,
    -- a text field to hold the maintainer
    maintainer_id	integer
			constraint arr_maintainer_id_fk references persons(person_id),
    -- this could be ancillary docs, pdf's etc
    -- needs to be fixed for PG
    notes blob
);

-- API

create or replace package acs_reference
as
create function acs_reference__new (integer,varchar,char,varchar,timestamp,
varchar,varchar,timestamp,timestamp,integer,blob,timestamp,
integer,varchar,integer)
returns integer as '
declare
    repository_id   alias for $1; -- default null
    table_name      alias for $2; -- 
    internal_data_p alias for $3; -- default 'f'
    package_name    alias for $4; -- default null
    last_update     alias for $5; -- default sysdate
    source          alias for $6; -- default null
    source_url      alias for $7; -- default null
    effective_date  alias for $8; -- default sysdate
    expiry_date     alias for $9; -- default null
    maintainer_id   alias for $10; -- default null
    notes           alias for $11; -- default empty_blob()
-- I really see no need for these as parameters
--    creation_date   alias for $12; -- default sysdate
    first_names     alias for $12; -- default null
    last_names      alias for $13; -- default null
    creation_ip     alias for $14; -- default null
    object_type     alias for $15; -- default 'acs_reference_repository'
    creation_user   alias for $16; -- default null
)
    if object_type is null then
        v_object_type := 'acs_reference_repository';
    else
        v_object_type := object_type;
    end if;

    v_repository_id := acs_object__new (
         object_id,    
         sysdate(),
         creation_user,
         creation_ip,
         v_object_type  
    );

    -- This logic isn't correct as the maintainer could already exist
    -- The way around this is a little clunky as you can search persons
    -- then pick an existing person or add a new one, to many screens!
    -- I really doubt the need for person anyway.
    --
    -- It probably needs to just be a UI function and pass
    -- in the value for maintainer.
    --
    -- IN OTHER WORDS
    -- Guaranteed to probably break in the future if you depend on
    -- first_names and last_name to still exist as a param
    -- This needs to be updated in the Oracle version also
    -- NEEDS TO BE FIXED - jag

    if first_names is not null and last_name is not null and maintainer_id is null then
        v_maintainer_id := person__new (
	    first_names,
            last_name,  
            null  -- email       
            );
	else if maintainer_id is not null
           v_maintainer_id := maintainer_id;
        else 
	    v_maintainer_id := null;
	end if;

        insert into acs_reference_repositories
            (repository_id,table_name,internal_data_p,
             last_update,package_name,source, 
             source_url,effective_date,expiry_date,
             maintainer_id,notes)
        values 
            (v_repository_id,table_name,internal_data_p,
             last_update,package_name,source,source_url,
             effective_date,expiry_date,v_maintainer_id,notes);
        return v_repository_id;    
end;
' language 'plpgsql';


create function acs_reference__delete (integer)
returns integer as '
declare
    repository_id alias for $1;
begin
    select maintainer_id into v_maintainer_id
    from   acs_reference_repositories
    where  repository_id = acs_reference__delete.repository_id;

    delete from acs_reference_repositories
    where repository_id = acs_reference__delete.repository_id;

    acs_object__delete(repository_id);
    -- Who added this it is ridiculous
    -- a person could exist from something else
--  person__delete(v_maintainer_id);
end;
' language 'plpgsql';

create function acs_reference__is_expired_p (integer)
returns char as '
declare
    repository_id alias for $1;
begin
    select expiry_date into v_expiry_date
    from   acs_reference_repositories
    where  repository_id = is_expired_p.repository_id;

    if nvl(v_expiry_date,sysdate()+1) < sysdate() then
        return 't';
    else
        return 'f';
    end if;
end;
' language 'plpgsql';

-- now load the reference data packages

\i acs-reference-data
