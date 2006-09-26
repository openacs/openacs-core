--
-- packages/acs-reference/sql/acs-reference-create.sql
--
-- @author jon@arsdigita.com
-- @creation-date 2000-11-21
-- @cvs-id $Id$

-- setup the basic admin privileges

begin 
    acs_privilege.create_privilege('acs_reference_create');
    acs_privilege.create_privilege('acs_reference_write');
    acs_privilege.create_privilege('acs_reference_read');
    acs_privilege.create_privilege('acs_reference_delete');
    
    acs_privilege.add_child('create','acs_reference_create');
    acs_privilege.add_child('write', 'acs_reference_write');
    acs_privilege.add_child('read',  'acs_reference_read');
    acs_privilege.add_child('delete','acs_reference_delete');
end;
/
show errors

-- Create the basic object type used to represent a reference database

begin
    acs_object_type.create_type (
        supertype     => 'acs_object',
        object_type   => 'acs_reference_repository',
        pretty_name   => 'ACS Reference Repository',
        pretty_plural => 'ACS Reference Repositories', 
        table_name    => 'acs_reference_repositories',
        id_column     => 'repository_id',
        name_method   => 'acs_object.default_name'
);
end;
/
show errors

-- A table to store metadata for each reference database

create table acs_reference_repositories (
    repository_id	integer
			constraint arr_repository_id_fk references acs_objects (object_id)
			constraint arr_repository_id_pk primary key,
    -- what is the table name we are monitoring
    table_name		varchar2(100)  
			constraint arr_table_name_nn not null
			constraint arr_table_name_un unique,
    -- is this external or internal data
    internal_data_p     char(1)       
			constraint arr_internal_data_p_ck
        		check (internal_data_p in ('t','f')),
    -- Does this source include pl/sql package?
    package_name	varchar2(100)
			constraint arr_package_name_un unique,
    -- last updated
    last_update		date,
    -- where is this data from
    source		varchar2(1000),
    source_url		varchar2(255),
    -- should default to today
    effective_date	date default sysdate,
    expiry_date		date,
    -- a text field to hold the maintainer
    maintainer_id	integer
			constraint arr_maintainer_id_fk references persons(person_id),
    -- this could be ancillary docs, pdf's etc
    notes blob
);

-- API

create or replace package acs_reference
as
    function new (
        repository_id   in acs_reference_repositories.repository_id%TYPE default null,
        table_name      in acs_reference_repositories.table_name%TYPE,
        internal_data_p in acs_reference_repositories.internal_data_p%TYPE default 'f',
        package_name    in acs_reference_repositories.package_name%TYPE default null,
        last_update     in acs_reference_repositories.last_update%TYPE default sysdate,
        source          in acs_reference_repositories.source%TYPE default null,
        source_url      in acs_reference_repositories.source_url%TYPE default null,
        effective_date  in acs_reference_repositories.effective_date%TYPE default sysdate,
        expiry_date     in acs_reference_repositories.expiry_date%TYPE default null,
        notes           in acs_reference_repositories.notes%TYPE default empty_blob(), 
        creation_date   in acs_objects.creation_date%TYPE default sysdate,
        creation_user   in acs_objects.creation_user%TYPE default null,
        creation_ip     in acs_objects.creation_ip%TYPE default null,
        object_type     in acs_objects.object_type%TYPE default 'acs_reference_repository',
        first_names     in persons.first_names%TYPE default null,
        last_name       in persons.last_name%TYPE default null
    ) return acs_objects.object_id%TYPE;

    procedure del (
        repository_id in acs_reference_repositories.repository_id%TYPE
    );

    function is_expired_p (
	repository_id integer
    ) return char;

 end acs_reference;
/
show errors


create or replace package body acs_reference
as
    function new (
        repository_id   in acs_reference_repositories.repository_id%TYPE default null,
        table_name      in acs_reference_repositories.table_name%TYPE,
        internal_data_p in acs_reference_repositories.internal_data_p%TYPE default 'f',
        package_name    in acs_reference_repositories.package_name%TYPE default null,
        last_update     in acs_reference_repositories.last_update%TYPE default sysdate,
        source          in acs_reference_repositories.source%TYPE default null,
        source_url      in acs_reference_repositories.source_url%TYPE default null,
        effective_date  in acs_reference_repositories.effective_date%TYPE default sysdate,
        expiry_date     in acs_reference_repositories.expiry_date%TYPE default null,
        notes           in acs_reference_repositories.notes%TYPE default empty_blob(), 
        creation_date   in acs_objects.creation_date%TYPE default sysdate,
        creation_user   in acs_objects.creation_user%TYPE default null,
        creation_ip     in acs_objects.creation_ip%TYPE default null,
        object_type     in acs_objects.object_type%TYPE default 'acs_reference_repository',
        first_names     in persons.first_names%TYPE default null,
        last_name       in persons.last_name%TYPE default null
    ) return acs_objects.object_id%TYPE
    is
        v_repository_id acs_reference_repositories.repository_id%TYPE;
        v_maintainer_id persons.person_id%TYPE;
    begin
        v_repository_id := acs_object.new (
             object_id     => repository_id,
             creation_date => creation_date,
             creation_user => creation_user,
             creation_ip   => creation_ip,
             object_type   => object_type,
             title         => source
        );

	if first_names is not null and last_name is not null then
            v_maintainer_id := person.new (
	         first_names   => first_names,
	         last_name     => last_name,
		 email         => null
            );
	else
	    v_maintainer_id := null;
	end if;

        insert into acs_reference_repositories
            (repository_id, 
             table_name,
             internal_data_p,
             last_update,
             package_name,
             source, 
             source_url,
             effective_date,
             expiry_date,
             maintainer_id,
             notes)
        values 
            (v_repository_id, 
             table_name,
             internal_data_p,
             last_update,
             package_name,
             source, 
             source_url,
             effective_date,
             expiry_date,
             v_maintainer_id,
             notes);
        return v_repository_id;    
    end new;

    procedure del (
        repository_id in acs_reference_repositories.repository_id%TYPE
    )
    is
	v_maintainer_id integer;
    begin
	select maintainer_id into v_maintainer_id
	from   acs_reference_repositories
	where  repository_id = acs_reference.del.repository_id;

        delete from acs_reference_repositories
        where  repository_id = acs_reference.del.repository_id;

        acs_object.del(repository_id);
	person.del(v_maintainer_id);

    end del;

    function is_expired_p (
	repository_id integer
    ) return char
    is
	v_expiry_date date;
    begin
	select expiry_date into v_expiry_date
	from   acs_reference_repositories
	where  repository_id = is_expired_p.repository_id;

	if nvl(v_expiry_date,sysdate+1) < sysdate then
	    return 't';
	else
	    return 'f';
	end if;
    end;	    

end acs_reference;
/
show errors
