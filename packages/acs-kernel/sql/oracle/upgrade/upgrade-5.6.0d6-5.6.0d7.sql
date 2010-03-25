
-- Public Programmer level API.
create or replace package apm
as
  procedure register_package (
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in apm_package_types.pretty_name%TYPE,
    pretty_plural		in apm_package_types.pretty_plural%TYPE,
    package_uri			in apm_package_types.package_uri%TYPE,
    package_type		in apm_package_types.package_type%TYPE,
    initial_install_p		in apm_package_types.initial_install_p%TYPE 
				default 'f',    
    singleton_p			in apm_package_types.singleton_p%TYPE 
				default 'f',    
    implements_subsite_p        in apm_package_types.implements_subsite_p%TYPE 
				default 'f',    
    inherit_templates_p         in apm_package_types.inherit_templates_p%TYPE 
				default 't',    
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
				default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE 
				default null
  );

  function update_package (
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in apm_package_types.pretty_name%TYPE
    	    	    	    	default null,
    pretty_plural		in apm_package_types.pretty_plural%TYPE
    	    	    	    	default null,
    package_uri			in apm_package_types.package_uri%TYPE
    	    	    	    	default null,
    package_type		in apm_package_types.package_type%TYPE
    	    	    	    	default null,
    initial_install_p		in apm_package_types.initial_install_p%TYPE 
    	    	    	    	default null,    
    singleton_p			in apm_package_types.singleton_p%TYPE 
    	    	    	    	default null,    
    implements_subsite_p        in apm_package_types.implements_subsite_p%TYPE 
				default null,    
    inherit_templates_p         in apm_package_types.inherit_templates_p%TYPE 
				default null,    
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
    	    	    	    	default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE 
				default null
  ) return apm_package_types.package_type%TYPE;   
   
  procedure unregister_package (
    package_key		in apm_package_types.package_key%TYPE,
    cascade_p		in char default 't'
  );

  function register_p (
    package_key		in apm_package_types.package_key%TYPE
  ) return integer;

  -- Informs the APM that this application is available for use.
  procedure register_application (
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in apm_package_types.pretty_name%TYPE,
    pretty_plural		in apm_package_types.pretty_plural%TYPE,
    package_uri			in apm_package_types.package_uri%TYPE,
    initial_install_p		in apm_package_types.initial_install_p%TYPE 
				default 'f',    
    singleton_p			in apm_package_types.singleton_p%TYPE 
				default 'f',    
    implements_subsite_p        in apm_package_types.implements_subsite_p%TYPE 
				default 'f',    
    inherit_templates_p         in apm_package_types.inherit_templates_p%TYPE 
				default 't',    
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
				default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE 
				default null
  );

  -- Remove the application from the system. 
  procedure unregister_application (
    package_key		in apm_package_types.package_key%TYPE,
    -- Delete all objects associated with this application.	
    cascade_p		in char default 'f'
  ); 

  procedure register_service (
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in apm_package_types.pretty_name%TYPE,
    pretty_plural		in apm_package_types.pretty_plural%TYPE,
    package_uri			in apm_package_types.package_uri%TYPE,
    initial_install_p		in apm_package_types.initial_install_p%TYPE 
				default 'f',    
    singleton_p			in apm_package_types.singleton_p%TYPE 
				default 'f',    
    implements_subsite_p        in apm_package_types.implements_subsite_p%TYPE 
				default 'f',    
    inherit_templates_p         in apm_package_types.inherit_templates_p%TYPE 
				default 't',    
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
				default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE 
				default null
  );

  -- Remove the service from the system. 
  procedure unregister_service (
    package_key		in apm_package_types.package_key%TYPE,
    -- Delete all objects associated with this service.	
    cascade_p		in char default 'f'
  ); 

  -- Indicate to APM that a parameter is available to the system.
  function register_parameter (
    parameter_id		in apm_parameters.parameter_id%TYPE 
				default null,
    package_key			in apm_parameters.package_key%TYPE,				
    parameter_name		in apm_parameters.parameter_name%TYPE,
    description			in apm_parameters.description%TYPE
				default null,
    scope                       in apm_parameters.scope%TYPE
                                default 'instance',
    datatype			in apm_parameters.datatype%TYPE 
				default 'string',
    default_value		in apm_parameters.default_value%TYPE 
				default null,
    section_name		in apm_parameters.section_name%TYPE
				default null,
    min_n_values		in apm_parameters.min_n_values%TYPE 
				default 1,
    max_n_values		in apm_parameters.max_n_values%TYPE 
				default 1
  ) return apm_parameters.parameter_id%TYPE;

  function update_parameter (
    parameter_id		in apm_parameters.parameter_id%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE
    	    	    	    	default null,
    description			in apm_parameters.description%TYPE
				default null,
    datatype			in apm_parameters.datatype%TYPE 
				default 'string',
    default_value		in apm_parameters.default_value%TYPE 
				default null,
    section_name		in apm_parameters.section_name%TYPE
				default null,
    min_n_values		in apm_parameters.min_n_values%TYPE 
				default 1,
    max_n_values		in apm_parameters.max_n_values%TYPE 
				default 1
  ) return apm_parameters.parameter_name%TYPE;

  function parameter_p(
    package_key                 in apm_package_types.package_key%TYPE,
    parameter_name              in apm_parameters.parameter_name%TYPE
  ) return integer;

  -- Remove any uses of this parameter.
  procedure unregister_parameter (
    parameter_id		in apm_parameters.parameter_id%TYPE 
				default null
  );

  function id_for_name (
    package_key in apm_parameters.package_key%TYPE,
    parameter_name in apm_parameters.parameter_name%TYPE
  ) return apm_parameters.parameter_id%TYPE;

  function id_for_name (
    package_id in apm_packages.package_id%TYPE,
    parameter_name in apm_parameters.parameter_name%TYPE
  ) return apm_parameters.parameter_id%TYPE;

  function get_value (
    package_id			in apm_packages.package_id%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE
  ) return apm_parameter_values.attr_value%TYPE;

  function get_value (
    package_key			in apm_packages.package_key%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE
  ) return apm_parameter_values.attr_value%TYPE;

  procedure set_value (
    package_id			in apm_packages.package_id%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE,
    attr_value			in apm_parameter_values.attr_value%TYPE
  );	

  procedure set_value (
    package_key			in apm_packages.package_key%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE,
    attr_value			in apm_parameter_values.attr_value%TYPE
  );	

end apm;
/
show errors

create or replace package body apm
as
  procedure register_package (
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in apm_package_types.pretty_name%TYPE,
    pretty_plural		in apm_package_types.pretty_plural%TYPE,
    package_uri			in apm_package_types.package_uri%TYPE,
    package_type		in apm_package_types.package_type%TYPE,
    initial_install_p		in apm_package_types.initial_install_p%TYPE 
				default 'f',    
    singleton_p			in apm_package_types.singleton_p%TYPE 
				default 'f',    
    implements_subsite_p        in apm_package_types.implements_subsite_p%TYPE 
				default 'f',    
    inherit_templates_p         in apm_package_types.inherit_templates_p%TYPE 
				default 't',    
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
				default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE 
				default null
  ) 
  is
  begin
    apm_package_type.create_type(
    	package_key => register_package.package_key,
	pretty_name => register_package.pretty_name,
	pretty_plural => register_package.pretty_plural,
	package_uri => register_package.package_uri,
	package_type => register_package.package_type,
	initial_install_p => register_package.initial_install_p,
	singleton_p => register_package.singleton_p,
	implements_subsite_p => register_package.implements_subsite_p,
	inherit_templates_p => register_package.inherit_templates_p,
	spec_file_path => register_package.spec_file_path,
	spec_file_mtime => spec_file_mtime
    );
  end register_package;

  function update_package (
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in apm_package_types.pretty_name%TYPE
    	    	    	    	default null,
    pretty_plural		in apm_package_types.pretty_plural%TYPE
    	    	    	    	default null,
    package_uri			in apm_package_types.package_uri%TYPE
    	    	    	    	default null,
    package_type		in apm_package_types.package_type%TYPE
    	    	    	    	default null,
    initial_install_p		in apm_package_types.initial_install_p%TYPE 
    	    	    	    	default null,    
    singleton_p			in apm_package_types.singleton_p%TYPE 
    	    	    	    	default null,    
    implements_subsite_p        in apm_package_types.implements_subsite_p%TYPE 
				default null,
    inherit_templates_p         in apm_package_types.inherit_templates_p%TYPE 
				default null,    
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
    	    	    	    	default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE 
				default null
  ) return apm_package_types.package_type%TYPE
  is
  begin
 
    return apm_package_type.update_type(
    	package_key => update_package.package_key,
	pretty_name => update_package.pretty_name,
	pretty_plural => update_package.pretty_plural,
	package_uri => update_package.package_uri,
	package_type => update_package.package_type,
	initial_install_p => update_package.initial_install_p,
	singleton_p => update_package.singleton_p,
	implements_subsite_p => update_package.implements_subsite_p,
	inherit_templates_p => update_package.inherit_templates_p,
	spec_file_path => update_package.spec_file_path,
	spec_file_mtime => update_package.spec_file_mtime
    );

  end update_package;    


 procedure unregister_package (
    package_key		in apm_package_types.package_key%TYPE,
    cascade_p		in char default 't'
  )
  is
  begin
   apm_package_type.drop_type(
	package_key => unregister_package.package_key,
	cascade_p => unregister_package.cascade_p
   );
  end unregister_package;

  function register_p (
    package_key		in apm_package_types.package_key%TYPE
  ) return integer
  is
    v_register_p integer;
  begin
    select decode(count(*),0,0,1) into v_register_p from apm_package_types 
    where package_key = register_p.package_key;
    return v_register_p;
  end register_p;

  procedure register_application (
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in apm_package_types.pretty_name%TYPE,
    pretty_plural		in apm_package_types.pretty_plural%TYPE,
    package_uri			in apm_package_types.package_uri%TYPE,
    initial_install_p		in apm_package_types.initial_install_p%TYPE 
				default 'f',    
    singleton_p			in apm_package_types.singleton_p%TYPE 
				default 'f',    
    implements_subsite_p        in apm_package_types.implements_subsite_p%TYPE 
				default 'f',    
    inherit_templates_p         in apm_package_types.inherit_templates_p%TYPE 
				default 't',    
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
				default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE 
				default null
  ) 
  is
  begin
    apm.register_package(
	package_key => register_application.package_key,
	pretty_name => register_application.pretty_name,
	pretty_plural => register_application.pretty_plural,
	package_uri => register_application.package_uri,
	package_type => 'apm_application',
	initial_install_p => register_application.initial_install_p,
	singleton_p => register_application.singleton_p,
	implements_subsite_p => register_application.implements_subsite_p,
	inherit_templates_p => register_application.inherit_templates_p,
	spec_file_path => register_application.spec_file_path,
	spec_file_mtime => register_application.spec_file_mtime
   ); 
  end register_application;  

  procedure unregister_application (
    package_key		in apm_package_types.package_key%TYPE,
    cascade_p		in char default 'f'
  )
  is
  begin
   apm.unregister_package (
	package_key => unregister_application.package_key,
	cascade_p => unregister_application.cascade_p
   );
  end unregister_application; 

  procedure register_service (
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in apm_package_types.pretty_name%TYPE,
    pretty_plural		in apm_package_types.pretty_plural%TYPE,
    package_uri			in apm_package_types.package_uri%TYPE,
    initial_install_p		in apm_package_types.initial_install_p%TYPE 
				default 'f',    
    singleton_p			in apm_package_types.singleton_p%TYPE 
				default 'f',    
    implements_subsite_p        in apm_package_types.implements_subsite_p%TYPE 
				default 'f',    
    inherit_templates_p         in apm_package_types.inherit_templates_p%TYPE 
				default 't',    
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
				default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE 
				default null
  ) 
  is
  begin
   apm.register_package(
	package_key => register_service.package_key,
	pretty_name => register_service.pretty_name,
	pretty_plural => register_service.pretty_plural,
	package_uri => register_service.package_uri,
	package_type => 'apm_service',
	initial_install_p => register_service.initial_install_p,
	singleton_p => register_service.singleton_p,
	implements_subsite_p => register_service.implements_subsite_p,
	inherit_templates_p => register_service.inherit_templates_p,
	spec_file_path => register_service.spec_file_path,
	spec_file_mtime => register_service.spec_file_mtime
   );   
  end register_service;

  procedure unregister_service (
    package_key		in apm_package_types.package_key%TYPE,
    cascade_p		in char default 'f'
  )
  is
  begin
   apm.unregister_package (
	package_key => unregister_service.package_key,
	cascade_p => unregister_service.cascade_p
   );
  end unregister_service;

  -- Indicate to APM that a parameter is available to the system.
  function register_parameter (
    parameter_id		in apm_parameters.parameter_id%TYPE 
				default null,
    package_key			in apm_parameters.package_key%TYPE,				
    parameter_name		in apm_parameters.parameter_name%TYPE,
    description			in apm_parameters.description%TYPE
				default null,
    scope                       in apm_parameters.scope%TYPE
                                default 'instance',
    datatype			in apm_parameters.datatype%TYPE 
				default 'string',
    default_value		in apm_parameters.default_value%TYPE 
				default null,
    section_name		in apm_parameters.section_name%TYPE
				default null,
    min_n_values		in apm_parameters.min_n_values%TYPE 
				default 1,
    max_n_values		in apm_parameters.max_n_values%TYPE 
				default 1
  ) return apm_parameters.parameter_id%TYPE
  is
    v_parameter_id apm_parameters.parameter_id%TYPE;
    v_value_id apm_parameter_values.value_id%TYPE;
  begin
    -- Create the new parameter.    
    v_parameter_id := acs_object.new(
       object_id => parameter_id,
       object_type => 'apm_parameter',
       title => register_parameter.package_key || ': Parameter ' || register_parameter.parameter_name
    );
    
    insert into apm_parameters 
    (parameter_id, parameter_name, description, package_key, datatype, scope,
    default_value, section_name, min_n_values, max_n_values)
    values
    (v_parameter_id, register_parameter.parameter_name, register_parameter.description,
    register_parameter.package_key, register_parameter.datatype, register_parameter.scope,
    register_parameter.default_value, register_parameter.section_name, 
    register_parameter.min_n_values, register_parameter.max_n_values);
    -- Propagate parameter to new instances.	
    if register_parameter.scope = 'instance' then
      for pkg in (select package_id from apm_packages where package_key = register_parameter.package_key)
        loop
        	v_value_id := apm_parameter_value.new(
  	    package_id => pkg.package_id,
  	    parameter_id => v_parameter_id, 
  	    attr_value => register_parameter.default_value
  	    ); 	
        end loop;		
    else
      v_value_id := apm_parameter_value.new(
  	                   package_id => null,
  	                   parameter_id => v_parameter_id, 
  	                   attr_value => register_parameter.default_value); 	
    end if;

    return v_parameter_id;
  end register_parameter;

    function update_parameter (
    parameter_id		in apm_parameters.parameter_id%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE
    	    	    	    	default null,
    description			in apm_parameters.description%TYPE
				default null,
    datatype			in apm_parameters.datatype%TYPE 
				default 'string',
    default_value		in apm_parameters.default_value%TYPE 
				default null,
    section_name		in apm_parameters.section_name%TYPE
				default null,
    min_n_values		in apm_parameters.min_n_values%TYPE 
				default 1,
    max_n_values		in apm_parameters.max_n_values%TYPE 
				default 1
  ) return apm_parameters.parameter_name%TYPE
  is
  begin
    update apm_parameters 
	set parameter_name = nvl(update_parameter.parameter_name, parameter_name),
            default_value  = nvl(update_parameter.default_value, default_value),
            datatype       = nvl(update_parameter.datatype, datatype), 
	    description	   = nvl(update_parameter.description, description),
	    section_name   = nvl(update_parameter.section_name, section_name),
            min_n_values   = nvl(update_parameter.min_n_values, min_n_values),
            max_n_values   = nvl(update_parameter.max_n_values, max_n_values)
      where parameter_id = update_parameter.parameter_id;

    update acs_objects
       set title = (select package_key || ': Parameter ' || parameter_name
                    from apm_parameters
                    where parameter_id = update_parameter.parameter_id)
     where object_id = update_parameter.parameter_id;

    return parameter_id;
  end;

  function parameter_p(
    package_key                 in apm_package_types.package_key%TYPE,
    parameter_name              in apm_parameters.parameter_name%TYPE
  ) return integer 
  is
    v_parameter_p integer;
  begin
    select decode(count(*),0,0,1) into v_parameter_p 
    from apm_parameters
    where package_key = parameter_p.package_key
    and parameter_name = parameter_p.parameter_name;
    return v_parameter_p;
  end parameter_p;

  procedure unregister_parameter (
    parameter_id		in apm_parameters.parameter_id%TYPE 
				default null
  )
  is
  begin
    delete from apm_parameter_values 
    where parameter_id = unregister_parameter.parameter_id;
    delete from apm_parameters 
    where parameter_id = unregister_parameter.parameter_id;
    acs_object.del(parameter_id);
  end unregister_parameter;

  function id_for_name (
    package_key			in apm_parameters.package_key%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE
  ) return apm_parameters.parameter_id%TYPE
  is
    a_parameter_id apm_parameters.parameter_id%TYPE; 
  begin
    select parameter_id into a_parameter_id
    from apm_parameters p
    where p.parameter_name = id_for_name.parameter_name and
          p.package_key = id_for_name.package_key;

    return a_parameter_id;

    exception when no_data_found then
      raise_application_error(-20000, 'The specified package ' || 
        id_for_name.package_key || ' AND/OR parameter ' || id_for_name.package_key || 
        ' do not exist');

  end id_for_name;

  function id_for_name (
    package_id			in apm_packages.package_id%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE
  ) return apm_parameters.parameter_id%TYPE
  is
    a_parameter_id apm_parameters.parameter_id%TYPE; 
  begin
    select parameter_id into a_parameter_id
    from apm_parameters p
    where p.parameter_name = id_for_name.parameter_name and
          p.package_key = (select package_key from apm_packages
                           where package_id = id_for_name.package_id);

    return a_parameter_id;

    exception when no_data_found then
      raise_application_error(-20000, 'The specified package ' || 
        id_for_name.package_id || ' AND/OR parameter ' || id_for_name.parameter_name || 
        ' do not exist');

  end id_for_name;

  function get_value (
    package_id			in apm_packages.package_id%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE
  ) return apm_parameter_values.attr_value%TYPE
  is
    parameter_id apm_parameter_values.parameter_id%TYPE;
    value apm_parameter_values.attr_value%TYPE;
  begin
    parameter_id := apm.id_for_name(package_id, parameter_name);

    select attr_value into value
    from apm_parameter_values v
    where v.package_id = get_value.package_id
      and parameter_id = get_value.parameter_id;

    return value;
  end get_value;	

  function get_value (
    package_key			in apm_packages.package_key%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE
  ) return apm_parameter_values.attr_value%TYPE
  is
    parameter_id apm_parameter_values.parameter_id%TYPE;
    value apm_parameter_values.attr_value%TYPE;
  begin
    parameter_id := apm.id_for_name(package_key, parameter_name);

    select attr_value into value from apm_parameter_values v
    where v.package_id is null
      and parameter_id = get_value.parameter_id;

    return value;
  end get_value;	

  procedure set_value (
    package_key			in apm_packages.package_key%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE,
    attr_value			in apm_parameter_values.attr_value%TYPE
  ) 
  is
    parameter_id apm_parameter_values.parameter_id%TYPE;
    value_id apm_parameter_values.value_id%TYPE;
  begin
    parameter_id := apm.id_for_name(package_key, parameter_name);

    select value_id into value_id from apm_parameter_values
    where parameter_id = set_value.parameter_id
      and package_id is null;

    update apm_parameter_values
    set attr_value = set_value.attr_value
    where parameter_id = set_value.parameter_id
    and package_id = null;


    exception
      when NO_DATA_FOUND
      then
        value_id := apm_parameter_value.new(
           package_id => null,
           parameter_id => set_value.parameter_id,
           attr_value => set_value.attr_value
        );

  end set_value;	

  procedure set_value (
    package_id			in apm_packages.package_id%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE,
    attr_value			in apm_parameter_values.attr_value%TYPE
  ) 
  is
    parameter_id apm_parameter_values.parameter_id%TYPE;
    value_id apm_parameter_values.value_id%TYPE;
  begin
    parameter_id := apm.id_for_name(package_id, parameter_name);

    select value_id into value_id from apm_parameter_values
    where parameter_id = set_value.parameter_id
      and package_id = set_value.package_id;

    update apm_parameter_values
    set attr_value = set_value.attr_value
    where parameter_id = set_value.parameter_id
    and package_id = set_value.package_id;


    exception
      when NO_DATA_FOUND
      then
        value_id := apm_parameter_value.new(
           package_id => set_value.package_id,
           parameter_id => set_value.parameter_id,
           attr_value => set_value.attr_value
        );

  end set_value;	

end apm;
/
show errors  

