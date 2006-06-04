create or replace function apm_package__new (integer,varchar,varchar,varchar,timestamptz,integer,varchar,integer)
returns integer as '
declare
  new__package_id             alias for $1;  -- default null  
  new__instance_name          alias for $2;  -- default null
  new__package_key            alias for $3;  
  new__object_type            alias for $4;  -- default ''apm_package''
  new__creation_date          alias for $5;  -- default now()
  new__creation_user          alias for $6;  -- default null
  new__creation_ip            alias for $7;  -- default null
  new__context_id             alias for $8;  -- default null
  v_singleton_p               integer;       
  v_package_type              apm_package_types.package_type%TYPE;
  v_num_instances             integer;       
  v_package_id                apm_packages.package_id%TYPE;
  v_instance_name             apm_packages.instance_name%TYPE;
begin
   v_singleton_p := apm_package__singleton_p(
			new__package_key
		    );
   v_num_instances := apm_package__num_instances(
			new__package_key
		    );
  
   if v_singleton_p = 1 and v_num_instances >= 1 then
       select package_id into v_package_id 
       from apm_packages
       where package_key = new__package_key;

       return v_package_id;
   else
       v_package_id := acs_object__new(
          new__package_id,
          new__object_type,
          new__creation_date,
          new__creation_user,
	  new__creation_ip,
	  new__context_id
	 );
       if new__instance_name is null or new__instance_name = '''' then 
	 v_instance_name := new__package_key || '' '' || v_package_id;
       else
	 v_instance_name := new__instance_name;
       end if;

       select package_type into v_package_type
       from apm_package_types
       where package_key = new__package_key;

       insert into apm_packages
       (package_id, package_key, instance_name)
       values
       (v_package_id, new__package_key, v_instance_name);

       update acs_objects
       set title = v_instance_name,
           package_id = v_package_id
       where object_id = v_package_id;

       if v_package_type = ''apm_application'' then
	   insert into apm_applications
	   (application_id)
	   values
	   (v_package_id);
       else
	   insert into apm_services
	   (service_id)
	   values
	   (v_package_id);
       end if;

       PERFORM apm_package__initialize_parameters(
	   v_package_id,
	   new__package_key
       );

       return v_package_id;

  end if;
end;' language 'plpgsql';
