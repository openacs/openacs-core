
create or replace package apm_package
as

function new (
  package_id		in apm_packages.package_id%TYPE 
			default null,
  instance_name		in apm_packages.instance_name%TYPE
			default null,
  package_key		in apm_packages.package_key%TYPE,
  object_type		in acs_objects.object_type%TYPE
			default 'apm_package', 
  creation_date		in acs_objects.creation_date%TYPE 
			default sysdate,
  creation_user		in acs_objects.creation_user%TYPE 
			default null,
  creation_ip		in acs_objects.creation_ip%TYPE 
			default null,
  context_id		in acs_objects.context_id%TYPE 
			default null
  ) return apm_packages.package_id%TYPE;

  procedure del (
   package_id		in apm_packages.package_id%TYPE
  );

  function initial_install_p (
	package_key		in apm_packages.package_key%TYPE
  ) return integer;

  function singleton_p (
	package_key		in apm_packages.package_key%TYPE
  ) return integer;

  function num_instances (
	package_key		in apm_package_types.package_key%TYPE
  ) return integer;

  function name (
    package_id		in apm_packages.package_id%TYPE
  ) return varchar2;

  function highest_version (
   package_key		in apm_package_types.package_key%TYPE
  ) return apm_package_versions.version_id%TYPE;
  
    function parent_id (
        package_id in apm_packages.package_id%TYPE
    ) return apm_packages.package_id%TYPE;

  function is_child (
    parent_package_key in apm_packages.package_key%TYPE,
    child_package_key in apm_packages.package_key%TYPE
  ) return char;

end apm_package;
/
show errors

create or replace package body apm_package
as
  procedure initialize_parameters (
    package_id			in apm_packages.package_id%TYPE,
    package_key		        in apm_package_types.package_key%TYPE
  )
  is
   v_value_id apm_parameter_values.value_id%TYPE;
   cursor cur is
       select parameter_id, default_value
       from apm_parameters
       where package_key = initialize_parameters.package_key;
  begin
    -- need to initialize all params for this type
    for cur_val in cur
      loop
        v_value_id := apm_parameter_value.new(
          package_id => initialize_parameters.package_id,
          parameter_id => cur_val.parameter_id,
          attr_value => cur_val.default_value
        ); 
      end loop;   
  end initialize_parameters;

 function new (
  package_id		in apm_packages.package_id%TYPE 
			default null,
  instance_name		in apm_packages.instance_name%TYPE
			default null,
  package_key		in apm_packages.package_key%TYPE,
  object_type		in acs_objects.object_type%TYPE
			default 'apm_package', 
  creation_date		in acs_objects.creation_date%TYPE 
			default sysdate,
  creation_user		in acs_objects.creation_user%TYPE 
			default null,
  creation_ip		in acs_objects.creation_ip%TYPE 
			default null,
  context_id		in acs_objects.context_id%TYPE 
			default null
  ) return apm_packages.package_id%TYPE
  is 
   v_singleton_p integer;
   v_package_type apm_package_types.package_type%TYPE;
   v_num_instances integer;
   v_package_id apm_packages.package_id%TYPE;
   v_instance_name apm_packages.instance_name%TYPE; 
  begin
   v_singleton_p := apm_package.singleton_p(
			package_key => apm_package.new.package_key
		    );
   v_num_instances := apm_package.num_instances(
			package_key => apm_package.new.package_key
		    );
  
   if v_singleton_p = 1 and v_num_instances >= 1 then
       select package_id into v_package_id 
       from apm_packages
       where package_key = apm_package.new.package_key;
       return v_package_id;
   else
       v_package_id := acs_object.new(
          object_id => package_id,
          object_type => object_type,
          creation_date => creation_date,
          creation_user => creation_user,
	  creation_ip => creation_ip,
	  context_id => context_id
	 );

       if instance_name is null then 
	 v_instance_name := package_key || ' ' || v_package_id;
       else
	 v_instance_name := instance_name;
       end if;

       insert into apm_packages
       (package_id, package_key, instance_name)
       values
       (v_package_id, package_key, v_instance_name);

       update acs_objects
       set title = v_instance_name,
           package_id = v_package_id
       where object_id = v_package_id;

       select package_type into v_package_type
       from apm_package_types
       where package_key = apm_package.new.package_key;

       if v_package_type = 'apm_application' then
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

       initialize_parameters(
	   package_id => v_package_id,
	   package_key => apm_package.new.package_key
       );
       return v_package_id;

  end if;
end new;
  
  procedure del (
   package_id		in apm_packages.package_id%TYPE
  )
  is
    cursor all_values is
    	select value_id from apm_parameter_values
	where package_id = apm_package.del.package_id;
    cursor all_site_nodes is
    	select node_id from site_nodes
	where object_id = apm_package.del.package_id;
  begin
    -- Delete all parameters.
    for cur_val in all_values loop
    	apm_parameter_value.del(value_id => cur_val.value_id);
    end loop;    
    delete from apm_applications where application_id = apm_package.del.package_id;
    delete from apm_services where service_id = apm_package.del.package_id;
    delete from apm_packages where package_id = apm_package.del.package_id;
    -- Delete the site nodes for the objects.
    for cur_val in all_site_nodes loop
    	site_node.del(cur_val.node_id);
    end loop;
    -- Delete the object.
    acs_object.del (
	object_id => package_id
    );
   end del;

    function initial_install_p (
	package_key		in apm_packages.package_key%TYPE
    ) return integer
    is
        v_initial_install_p integer;
    begin
        select 1 into v_initial_install_p
	from apm_package_types
	where package_key = initial_install_p.package_key
        and initial_install_p = 't';
	return v_initial_install_p;
	
	exception 
	    when NO_DATA_FOUND
            then
                return 0;
    end initial_install_p;

    function singleton_p (
	package_key		in apm_packages.package_key%TYPE
    ) return integer
    is
        v_singleton_p integer;
    begin
        select 1 into v_singleton_p
	from apm_package_types
	where package_key = singleton_p.package_key
        and singleton_p = 't';
	return v_singleton_p;
	
	exception 
	    when NO_DATA_FOUND
            then
                return 0;
    end singleton_p;

    function num_instances (
	package_key		in apm_package_types.package_key%TYPE
    ) return integer
    is
        v_num_instances integer;
    begin
        select count(*) into v_num_instances
	from apm_packages
	where package_key = num_instances.package_key;
        return v_num_instances;
	
	exception
	    when NO_DATA_FOUND
	    then
	        return 0;
    end num_instances;

  function name (
    package_id		in apm_packages.package_id%TYPE
  ) return varchar2
  is
    v_result apm_packages.instance_name%TYPE;
  begin
    select instance_name into v_result
    from apm_packages
    where package_id = name.package_id;

    return v_result;
  end name;

   function highest_version (
     package_key		in apm_package_types.package_key%TYPE
   ) return apm_package_versions.version_id%TYPE
   is
     v_version_id apm_package_versions.version_id%TYPE;
   begin
     select version_id into v_version_id
	from apm_package_version_info i 
	where apm_package_version.sortable_version_name(version_name) = 
             (select max(apm_package_version.sortable_version_name(v.version_name))
	             from apm_package_version_info v where v.package_key = highest_version.package_key)
	and package_key = highest_version.package_key;
     return v_version_id;
     exception
         when NO_DATA_FOUND
         then
         return 0;
   end highest_version;

    function parent_id (
        package_id in apm_packages.package_id%TYPE
    ) return apm_packages.package_id%TYPE
    is
        v_package_id apm_packages.package_id%TYPE;
    begin
        select sn1.object_id
        into v_package_id
        from site_nodes sn1
        where sn1.node_id = (select sn2.parent_id
                             from site_nodes sn2
                             where sn2.object_id = apm_package.parent_id.package_id);

        return v_package_id;

        exception when NO_DATA_FOUND then
            return -1;
    end parent_id;

  function is_child (
    parent_package_key in apm_packages.package_key%TYPE,
    child_package_key in apm_packages.package_key%TYPE
  ) return char
    is
    begin

      if parent_package_key = child_package_key then
        return 't';
      end if;

      for row in
        (select apd.service_uri
         from apm_package_versions apv, apm_package_dependencies apd
         where apd.version_id = apv.version_id
           and apv.enabled_p = 't'
           and apd.dependency_type in ('embeds', 'extends')
           and apv.package_key = child_package_key)
      loop
        if row.service_uri = parent_package_key or
          is_child(parent_package_key, row.service_uri) = 't' then
        return 't';
      end if;
    end loop;
 
    return 'f';
  end is_child;

end apm_package;
/
show errors

