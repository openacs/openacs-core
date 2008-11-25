 insert into acs_datatypes
  (datatype, max_n_values)
 values
  ('file', 1);

alter table apm_package_dependencies drop constraint apm_package_deps_type_ck;
alter table apm_package_dependencies add
  constraint apm_package_deps_type_ck
  check (dependency_type in ('provides', 'requires', 'extends'));

-- function add_dependency
create or replace function apm_package_version__add_dependency (varchar,integer,integer,varchar,varchar)
returns integer as '
declare
  add_dependency__dependency_type        alias for $1;
  add_dependency__dependency_id          alias for $2;  -- default null  
  add_dependency__version_id             alias for $3;  
  add_dependency__dependency_uri         alias for $4;  
  add_dependency__dependency_version     alias for $5;  
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
      (v_dep_id, add_dependency__version_id, add_dependency__dependency_type,
        add_dependency__dependency_uri, add_dependency__dependency_version);

      return v_dep_id;
   
end;' language 'plpgsql';

alter table apm_package_types add implements_subsite_p boolean default 'f';
update apm_package_types set implements_subsite_p = 't' where package_key = 'acs-subsite';

alter table apm_package_types add inherit_templates_p boolean default 't';

drop view apm_enabled_package_versions;
drop view apm_package_version_info;

create or replace view apm_package_version_info as
    select v.package_key, t.package_uri, t.pretty_name, t.singleton_p, t.initial_install_p,
           t.inherit_templates_p, t.implements_subsite_p,
           v.version_id, v.version_name,
           v.version_uri, v.summary, v.description_format, v.description, v.release_date,
           v.vendor, v.vendor_uri, v.auto_mount, v.enabled_p, v.installed_p, v.tagged_p,
           v.imported_p, v.data_model_loaded_p,
           v.activation_date, v.deactivation_date,
           coalesce(v.content_length,0) as tarball_length,
           distribution_uri, distribution_date
    from   apm_package_types t, apm_package_versions v 
    where  v.package_key = t.package_key;

-- A useful view for simply determining which packages are eanbled.
create view apm_enabled_package_versions as
    select * from apm_package_version_info
    where  enabled_p = 't';

create or replace function apm__register_package (varchar,varchar,varchar,varchar,varchar,boolean,boolean,boolean,boolean,varchar,integer)
returns integer as '
declare
  package_key            alias for $1;  
  pretty_name            alias for $2;  
  pretty_plural          alias for $3;  
  package_uri            alias for $4;  
  package_type           alias for $5;  
  initial_install_p      alias for $6;  -- default ''f''  
  singleton_p            alias for $7;  -- default ''f''  
  implements_subsite_p   alias for $8;  -- default ''f''  
  inherit_templates_p   alias for $9;  -- default ''f''  
  spec_file_path         alias for $10;  -- default null
  spec_file_mtime        alias for $11;  -- default null
begin
    PERFORM apm_package_type__create_type(
    	package_key,
	pretty_name,
	pretty_plural,
	package_uri,
	package_type,
	initial_install_p,
	singleton_p,
        implements_subsite_p,
        inherit_templates_p,
	spec_file_path,
	spec_file_mtime
    );

    return 0; 
end;' language 'plpgsql';


-- function update_package
create or replace function apm__update_package (varchar,varchar,varchar,varchar,varchar,boolean,boolean,boolean,boolean,varchar,integer)
returns varchar as '
declare
  package_key            alias for $1;  
  pretty_name            alias for $2;  -- default null
  pretty_plural          alias for $3;  -- default null  
  package_uri            alias for $4;  -- default null  
  package_type           alias for $5;  -- default null  
  initial_install_p      alias for $6;  -- default null  
  singleton_p            alias for $7;  -- default null  
  implements_subsite_p   alias for $8;  -- default ''f''  
  inherit_templates_p   alias for $9;  -- default ''f''  
  spec_file_path         alias for $10;  -- default null
  spec_file_mtime        alias for $11;  -- default null
begin
 
    return apm_package_type__update_type(
    	package_key,
	pretty_name,
	pretty_plural,
	package_uri,
	package_type,
	initial_install_p,
	singleton_p,
        implements_subsite_p,
        inherit_templates_p,
	spec_file_path,
	spec_file_mtime
    );
   
end;' language 'plpgsql';

create or replace function apm_package_type__create_type (varchar,varchar,varchar,varchar,varchar,boolean,boolean,boolean,boolean,varchar,integer)
returns integer as '
declare
  create_type__package_key            alias for $1;  
  create_type__pretty_name            alias for $2;  
  create_type__pretty_plural          alias for $3;  
  create_type__package_uri            alias for $4;  
  create_type__package_type           alias for $5;  
  create_type__initial_install_p      alias for $6;  
  create_type__singleton_p            alias for $7;  
  create_type__implements_subsite_p   alias for $8;  
  create_type__inherit_templates_p   alias for $9;  
  create_type__spec_file_path         alias for $10;  -- default null  
  create_type__spec_file_mtime        alias for $11;  -- default null
begin
   insert into apm_package_types
    (package_key, pretty_name, pretty_plural, package_uri, package_type,
    spec_file_path, spec_file_mtime, initial_install_p, singleton_p,
    implements_subsite_p, inherit_templates_p)
   values
    (create_type__package_key, create_type__pretty_name, create_type__pretty_plural,
     create_type__package_uri, create_type__package_type, create_type__spec_file_path, 
     create_type__spec_file_mtime, create_type__initial_install_p, create_type__singleton_p,
     create_type__implements_subsite_p, create_type__inherit_templates_p);

   return 0; 
end;' language 'plpgsql';


-- function update_type
create or replace function apm_package_type__update_type (varchar,varchar,varchar,varchar,varchar,boolean,boolean,boolean,boolean,varchar,integer)
returns varchar as '
declare
  update_type__package_key            alias for $1;  
  update_type__pretty_name            alias for $2;  -- default null  
  update_type__pretty_plural          alias for $3;  -- default null
  update_type__package_uri            alias for $4;  -- default null
  update_type__package_type           alias for $5;  -- default null  
  update_type__initial_install_p      alias for $6;  -- default null  
  update_type__singleton_p            alias for $7;  -- default null  
  update_type__implements_subsite_p   alias for $8;  
  update_type__inherit_templates_p            alias for $9;  
  update_type__spec_file_path         alias for $10;  -- default null  
  update_type__spec_file_mtime        alias for $11;  -- default null
begin
      UPDATE apm_package_types SET
      	pretty_name = coalesce(update_type__pretty_name, pretty_name),
    	pretty_plural = coalesce(update_type__pretty_plural, pretty_plural),
    	package_uri = coalesce(update_type__package_uri, package_uri),
    	package_type = coalesce(update_type__package_type, package_type),
    	spec_file_path = coalesce(update_type__spec_file_path, spec_file_path),
    	spec_file_mtime = coalesce(update_type__spec_file_mtime, spec_file_mtime),
    	singleton_p = coalesce(update_type__singleton_p, singleton_p),
    	initial_install_p = coalesce(update_type__initial_install_p, initial_install_p),
        implements_subsite_p = coalesce(update_type__implements_subsite_p, implements_subsite_p),
        inherit_templates_p = coalesce(update_type__inherit_templates_p, inherit_templates_p)
      where package_key = update_type__package_key;

      return update_type__package_key;
   
end;' language 'plpgsql';

-- procedure register_application
create or replace function apm__register_application (varchar,varchar,varchar,varchar,boolean,boolean,boolean,boolean,varchar,integer)
returns integer as '
declare
  package_key            alias for $1;  
  pretty_name            alias for $2;  
  pretty_plural          alias for $3;  
  package_uri            alias for $4;  
  initial_install_p      alias for $5;  -- default ''f'' 
  singleton_p            alias for $6;  -- default ''f'' 
  implements_subsite_p   alias for $7;  -- default ''f''  
  inherit_templates_p   alias for $8;  -- default ''f''  
  spec_file_path         alias for $9;  -- default null
  spec_file_mtime        alias for $10;  -- default null
begin
   PERFORM apm__register_package(
	package_key,
	pretty_name,
	pretty_plural,
	package_uri,
	''apm_application'',
	initial_install_p,
	singleton_p,
        implements_subsite_p,
        inherit_templates_p,
	spec_file_path,
	spec_file_mtime
   ); 

   return 0; 
end;' language 'plpgsql';

-- procedure register_service
create or replace function apm__register_service (varchar,varchar,varchar,varchar,boolean,boolean,boolean,boolean,varchar,integer)
returns integer as '
declare
  package_key            alias for $1;  
  pretty_name            alias for $2;  
  pretty_plural          alias for $3;  
  package_uri            alias for $4;  
  initial_install_p      alias for $5;  -- default ''f''  
  singleton_p            alias for $6;  -- default ''f''  
  implements_subsite_p   alias for $7;  -- default ''f''  
  inherit_templates_p   alias for $8;  -- default ''f''  
  spec_file_path         alias for $9;  -- default null
  spec_file_mtime        alias for $10;  -- default null
begin
   PERFORM apm__register_package(
	package_key,
	pretty_name,
	pretty_plural,
	package_uri,
	''apm_service'',
	initial_install_p,
	singleton_p,
        implements_subsite_p,
        inherit_templates_p,
	spec_file_path,
	spec_file_mtime
   );  
 
   return 0; 
end;' language 'plpgsql';

create or replace function apm_package__is_child(varchar, varchar) returns boolean as '
declare
  parent_package_key       alias for $1;
  child_package_key        alias for $2;
  dependency               record;
begin

  if parent_package_key = child_package_key then
    return ''t'';
  end if;

  for dependency in 
    select apd.service_uri
    from apm_package_versions apv, apm_package_dependencies apd
    where apd.version_id = apv.version_id
      and apv.enabled_p
      and apd.dependency_type = ''extends''
      and apv.package_key = child_package_key
  loop
    if dependency.service_uri = parent_package_key or
      apm_package__is_child(parent_package_key, dependency.service_uri) then
      return ''t'';
    end if;
  end loop;
      
  return ''f'';
end;' language 'plpgsql';
