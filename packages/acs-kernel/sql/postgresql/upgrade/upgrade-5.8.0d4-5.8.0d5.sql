-- added
select define_function_args('apm__register_parameter','parameter_id;null,package_key,parameter_name,description;null,scope,datatype;string,default_value;null,section_name;null,min_n_values;1,max_n_values;1');

--
-- procedure apm__register_parameter/10
--
CREATE OR REPLACE FUNCTION apm__register_parameter(
   register_parameter__parameter_id integer,  -- default null
   register_parameter__package_key varchar,
   register_parameter__parameter_name varchar,
   register_parameter__description varchar,   -- default null
   register_parameter__scope varchar,
   register_parameter__datatype varchar,      -- default 'string'
   register_parameter__default_value varchar, -- default null
   register_parameter__section_name varchar,  -- default null
   register_parameter__min_n_values integer,  -- default 1
   register_parameter__max_n_values integer   -- default 1

) RETURNS integer AS $$
DECLARE

  v_parameter_id         apm_parameters.parameter_id%TYPE;
  v_value_id             apm_parameter_values.value_id%TYPE;
  v_pkg                  record;

BEGIN
    -- Create the new parameter.    
    v_parameter_id := acs_object__new(
       register_parameter__parameter_id,
       'apm_parameter',
       now(),
       null,
       null,
       null,
       't',
       register_parameter__package_key || ' - ' || register_parameter__parameter_name,
       null
    );
    
    insert into apm_parameters 
    (parameter_id, parameter_name, scope, description, package_key, datatype, 
    default_value, section_name, min_n_values, max_n_values)
    values
    (v_parameter_id, register_parameter__parameter_name, register_parameter__scope,
     register_parameter__description, register_parameter__package_key, 
     register_parameter__datatype, register_parameter__default_value, 
     register_parameter__section_name, register_parameter__min_n_values, 
     register_parameter__max_n_values);

    -- Propagate parameter to new instances.	
    if register_parameter__scope = 'instance' then
      for v_pkg in
          select package_id
  	from apm_packages
  	where package_key = register_parameter__package_key
        loop
          v_value_id := apm_parameter_value__new(
  	    null,
  	    v_pkg.package_id,
  	    v_parameter_id, 
  	    register_parameter__default_value); 	
        end loop;		
     else
       v_value_id := apm_parameter_value__new(
  	 null,
  	 null,
  	 v_parameter_id, 
  	 register_parameter__default_value); 	
     end if;
	
    return v_parameter_id;
   
END;
$$ LANGUAGE plpgsql;
