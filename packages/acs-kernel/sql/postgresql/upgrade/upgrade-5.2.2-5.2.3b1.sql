create or replace function apm_package_type__update_type (varchar,varchar,varchar,varchar,varchar,boolean,boolean,varchar,integer)
returns varchar as '
declare
  update_type__package_key            alias for $1;  
  update_type__pretty_name            alias for $2;  -- default null  
  update_type__pretty_plural          alias for $3;  -- default null
  update_type__package_uri            alias for $4;  -- default null
  update_type__package_type           alias for $5;  -- default null  
  update_type__initial_install_p      alias for $6;  -- default null  
  update_type__singleton_p            alias for $7;  -- default null  
  update_type__spec_file_path         alias for $8;  -- default null  
  update_type__spec_file_mtime        alias for $9;  -- default null  
begin
      UPDATE apm_package_types SET
      	pretty_name = coalesce(update_type__pretty_name, pretty_name),
    	pretty_plural = coalesce(update_type__pretty_plural, pretty_plural),
    	package_uri = coalesce(update_type__package_uri, package_uri),
    	package_type = coalesce(update_type__package_type, package_type),
    	spec_file_path = coalesce(update_type__spec_file_path, spec_file_path),
    	spec_file_mtime = coalesce(update_type__spec_file_mtime, spec_file_mtime),
    	singleton_p = coalesce(update_type__singleton_p, singleton_p),
    	initial_install_p = coalesce(update_type__initial_install_p, initial_install_p)
      where package_key = update_type__package_key;

      return update_type__package_key;
   
end;' language 'plpgsql';
