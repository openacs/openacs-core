-- Callbacks
create table apm_package_callbacks (
    version_id         integer 
                       constraint apm_package_callbacks_vid_fk 
                       references apm_package_versions(version_id)
                       on delete cascade,
    type               varchar(40),
    proc               varchar(300),
    constraint apm_package_callbacks_vt_un
    unique (version_id, type)
);

comment on table apm_package_callbacks is '
  This table holds names of Tcl procedures to invoke at the time (before or after) the package is
  installed, instantiated, or mounted.        
';

comment on column apm_package_callbacks.proc is '
  Name of the Tcl proc.
';

comment on column apm_package_callbacks.type is '
  Indicates when the callback proc should be invoked, for example after-install. Valid
  values are given by the Tcl proc apm_supported_callback_types.
';

-- Add column for auto-mount
alter table apm_package_versions add auto_mount varchar(50);

comment on column apm_package_versions.auto_mount is '
 A dir under the main site site node where an instance of the package will be mounted
 automatically upon installation. Useful for site-wide services that need mounting
 such as general-comments and notifications.
';

-- Recreate views for auto-mount
drop view apm_package_version_info;
create view apm_package_version_info as
    select v.package_key, t.package_uri, t.pretty_name, t.singleton_p, t.initial_install_p,
           v.version_id, v.version_name,
           v.version_uri, v.summary, v.description_format, v.description, v.release_date,
           v.vendor, v.vendor_uri, v.auto_mount, v.enabled_p, v.installed_p, v.tagged_p, v.imported_p, v.data_model_loaded_p,
           v.activation_date, v.deactivation_date,
           coalesce(v.content_length,0) as tarball_length,
           distribution_uri, distribution_date
    from   apm_package_types t, apm_package_versions v 
    where  v.package_key = t.package_key;

drop view apm_enabled_package_versions;
create view apm_enabled_package_versions as
    select * from apm_package_version_info
    where  enabled_p = 't';

-- Recreate functions for auto-mount
create or replace function apm_package_version__new (integer,varchar,varchar,varchar,varchar,varchar,varchar,timestamptz,varchar,varchar,varchar,boolean,boolean) returns integer as '
declare
      apm_pkg_ver__version_id           alias for $1;  -- default null
      apm_pkg_ver__package_key		alias for $2;
      apm_pkg_ver__version_name		alias for $3;  -- default null
      apm_pkg_ver__version_uri		alias for $4;
      apm_pkg_ver__summary              alias for $5;
      apm_pkg_ver__description_format	alias for $6;
      apm_pkg_ver__description		alias for $7;
      apm_pkg_ver__release_date		alias for $8;
      apm_pkg_ver__vendor               alias for $9;
      apm_pkg_ver__vendor_uri		alias for $10;
      apm_pkg_ver__auto_mount           alias for $11;
      apm_pkg_ver__installed_p		alias for $12; -- default ''f''		
      apm_pkg_ver__data_model_loaded_p	alias for $13; -- default ''f''
      v_version_id                      apm_package_versions.version_id%TYPE;
begin
      if apm_pkg_ver__version_id is null then
         select nextval(''t_acs_object_id_seq'')
	 into v_version_id
	 from dual;
      else
         v_version_id := apm_pkg_ver__version_id;
      end if;

      v_version_id := acs_object__new(
		v_version_id,
		''apm_package_version'',
                now(),
                null,
                null,
                null
        );

      insert into apm_package_versions
      (version_id, package_key, version_name, version_uri, summary, description_format, description,
      release_date, vendor, vendor_uri, auto_mount, installed_p, data_model_loaded_p)
      values
      (v_version_id, apm_pkg_ver__package_key, apm_pkg_ver__version_name, 
       apm_pkg_ver__version_uri, apm_pkg_ver__summary, 
       apm_pkg_ver__description_format, apm_pkg_ver__description,
       apm_pkg_ver__release_date, apm_pkg_ver__vendor, apm_pkg_ver__vendor_uri, apm_pkg_ver__auto_mount,
       apm_pkg_ver__installed_p, apm_pkg_ver__data_model_loaded_p);

      return v_version_id;		
  
end;' language 'plpgsql';

create or replace function apm_package_version__edit (integer,integer,varchar,varchar,varchar,varchar,varchar,timestamptz,varchar,varchar,varchar,boolean,boolean)
returns integer as '
declare
  edit__new_version_id         alias for $1;  -- default null  
  edit__version_id             alias for $2;  
  edit__version_name           alias for $3;  -- default null
  edit__version_uri            alias for $4;  
  edit__summary                alias for $5;  
  edit__description_format     alias for $6;  
  edit__description            alias for $7;  
  edit__release_date           alias for $8;  
  edit__vendor                 alias for $9;  
  edit__vendor_uri             alias for $10; 
  edit__auto_mount             alias for $11;
  edit__installed_p            alias for $12; -- default ''f''
  edit__data_model_loaded_p    alias for $13; -- default ''f''
  v_version_id                 apm_package_versions.version_id%TYPE;
  version_unchanged_p          integer;       
begin
       -- Determine if version has changed.
       select case when count(*) = 0 then 0 else 1 end into version_unchanged_p
       from apm_package_versions
       where version_id = edit__version_id
       and version_name = edit__version_name;
       if version_unchanged_p <> 1 then
         v_version_id := apm_package_version__copy(
			 edit__version_id,
			 edit__new_version_id,
			 edit__version_name,
			 edit__version_uri,
                         ''f''
			);
         else 
	   v_version_id := edit__version_id;			
       end if;
       
       update apm_package_versions 
		set version_uri = edit__version_uri,
		summary = edit__summary,
		description_format = edit__description_format,
		description = edit__description,
		release_date = date_trunc(''days'',now()),
		vendor = edit__vendor,
		vendor_uri = edit__vendor_uri,
                auto_mount = edit__auto_mount,
		installed_p = edit__installed_p,
		data_model_loaded_p = edit__data_model_loaded_p
	    where version_id = v_version_id;

	return v_version_id;
     
end;' language 'plpgsql';

create or replace function apm_package_version__copy (integer,integer,varchar,varchar,boolean)
returns integer as '
declare
  copy__version_id             alias for $1;  
  copy__new_version_id         alias for $2;  -- default null  
  copy__new_version_name       alias for $3;  
  copy__new_version_uri        alias for $4;  
  copy__copy_owners_p          alias for $5;
  v_version_id                 integer;       
begin
	v_version_id := acs_object__new(
		copy__new_version_id,
		''apm_package_version'',
                now(),
                null,
                null,
                null
        );    

	insert into apm_package_versions(version_id, package_key, version_name,
					version_uri, summary, description_format, description,
					release_date, vendor, vendor_uri, auto_mount)
	    select v_version_id, package_key, copy__new_version_name,
		   copy__new_version_uri, summary, description_format, description,
		   release_date, vendor, vendor_uri, auto_mount
	    from apm_package_versions
	    where version_id = copy__version_id;
    
	insert into apm_package_dependencies(dependency_id, version_id, dependency_type, service_uri, service_version)
	    select nextval(''t_acs_object_id_seq''), v_version_id, dependency_type, service_uri, service_version
	    from apm_package_dependencies
	    where version_id = copy__version_id;
    
	insert into apm_package_files(file_id, version_id, path, file_type, db_type)
	    select nextval(''t_acs_object_id_seq''), v_version_id, path, file_type, db_type
	    from apm_package_files
	    where version_id = copy__version_id;

        insert into apm_package_callbacks (version_id, type, proc)
                select v_version_id, type, proc
                from apm_package_callbacks
                where version_id = copy__version_id;
    
        if copy__copy_owners_p then
            insert into apm_package_owners(version_id, owner_uri, owner_name, sort_key)
                select v_version_id, owner_uri, owner_name, sort_key
                from apm_package_owners
                where version_id = copy__version_id;
        end if;
    
	return v_version_id;
   
end;' language 'plpgsql';
