-- @author Eric Lorenzo (eric@openforce.net)
-- @creation-date 2002/10/24


-- apm-create.sql - Converting nextval references to not use view;
-- bug causes failure in some cases.

-- create or replace package body apm_package_version 
create or replace function apm_package_version__new (integer,varchar,varchar,varchar,varchar,varchar,varchar,timestamp,varchar,varchar,boolean,boolean) returns integer as '
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
      apm_pkg_ver__installed_p		alias for $11; -- default ''f''		
      apm_pkg_ver__data_model_loaded_p	alias for $12; -- default ''f''
      v_version_id                      apm_package_versions.version_id%TYPE;
begin
      if apm_pkg_ver__version_id = '''' or apm_pkg_ver__version_id is null then
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
      release_date, vendor, vendor_uri, installed_p, data_model_loaded_p)
      values
      (v_version_id, apm_pkg_ver__package_key, apm_pkg_ver__version_name, 
       apm_pkg_ver__version_uri, apm_pkg_ver__summary, 
       apm_pkg_ver__description_format, apm_pkg_ver__description,
       apm_pkg_ver__release_date, apm_pkg_ver__vendor, apm_pkg_ver__vendor_uri,
       apm_pkg_ver__installed_p, apm_pkg_ver__data_model_loaded_p);

      return v_version_id;		
  
end;' language 'plpgsql';


-- function copy
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
					release_date, vendor, vendor_uri)
	    select v_version_id, package_key, copy__new_version_name,
		   copy__new_version_uri, summary, description_format, description,
		   release_date, vendor, vendor_uri
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
    
        if copy__copy_owners_p then
            insert into apm_package_owners(version_id, owner_uri, owner_name, sort_key)
                select v_version_id, owner_uri, owner_name, sort_key
                from apm_package_owners
                where version_id = copy__version_id;
        end if;
    
	return v_version_id;
   
end;' language 'plpgsql';


-- function add_file
create or replace function apm_package_version__add_file (integer,integer,varchar,varchar, varchar)
returns integer as '
declare
  add_file__file_id                alias for $1;  -- default null  
  add_file__version_id             alias for $2;  
  add_file__path                   alias for $3;  
  add_file__file_type              alias for $4;  
  add_file__db_type                alias for $5;  -- default null
  v_file_id                        apm_package_files.file_id%TYPE;
  v_file_exists_p                  integer;       
begin
	select file_id into v_file_id from apm_package_files
  	where version_id = add_file__version_id 
	and path = add_file__path;

	if NOT FOUND 
	       then
	       	if add_file__file_id is null then
	          select nextval(''t_acs_object_id_seq'') into v_file_id from dual;
	        else
	          v_file_id := add_file__file_id;
	        end if;

  	        insert into apm_package_files 
		(file_id, version_id, path, file_type, db_type) 
		values 
		(v_file_id, add_file__version_id, add_file__path, add_file__file_type, add_file__db_type);
        end if;

        return v_file_id;
   
end;' language 'plpgsql';


-- function add_interface
create or replace function apm_package_version__add_interface (integer,integer,varchar,varchar)
returns integer as '
declare
  add_interface__interface_id         alias for $1;  -- default null  
  add_interface__version_id           alias for $2;  
  add_interface__interface_uri        alias for $3;  
  add_interface__interface_version    alias for $4;  
  v_dep_id                            apm_package_dependencies.dependency_id%TYPE;
begin
      if add_interface__interface_id is null then
          select nextval(''t_acs_object_id_seq'') into v_dep_id from dual;
      else
          v_dep_id := add_interface__interface_id;
      end if;
  
      insert into apm_package_dependencies
      (dependency_id, version_id, dependency_type, service_uri, service_version)
      values
      (v_dep_id, add_interface__version_id, ''provides'', add_interface__interface_uri,
	add_interface__interface_version);

      return v_dep_id;
   
end;' language 'plpgsql';


-- function add_dependency
create or replace function apm_package_version__add_dependency (integer,integer,varchar,varchar)
returns integer as '
declare
  add_dependency__dependency_id          alias for $1;  -- default null  
  add_dependency__version_id             alias for $2;  
  add_dependency__dependency_uri         alias for $3;  
  add_dependency__dependency_version     alias for $4;  
  v_dep_id                            apm_package_dependencies.dependency_id%TYPE;
begin
      if add_dependency__dependency_id is null then
          select nextval(''t_acs_object_id_seq'') into v_dep_id from dual;
      else
          v_dep_id := add_dependency__dependency_id;
      end if;
  
      insert into apm_package_dependencies
      (dependency_id, version_id, dependency_type, service_uri, service_version)
      values
      (v_dep_id, add_dependency__version_id, ''requires'', add_dependency__dependency_uri,
	add_dependency__dependency_version);

      return v_dep_id;
   
end;' language 'plpgsql';


-- show errors
