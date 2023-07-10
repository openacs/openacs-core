
select define_function_args('apm__set_global_value','package_key,parameter_name,attr_value');

--
-- procedure apm__set_global_value/3
--
CREATE OR REPLACE FUNCTION apm__set_global_value(
   set_value__package_key varchar,
   set_value__parameter_name varchar,
   set_value__attr_value varchar
) RETURNS integer AS $$
DECLARE
  v_parameter_id                    apm_parameter_values.parameter_id%TYPE;
  v_value_id                        apm_parameter_values.value_id%TYPE;
BEGIN
    v_parameter_id := apm__id_for_name (set_value__package_key, set_value__parameter_name);

    -- Determine if the value exists
    select value_id into v_value_id from apm_parameter_values 
     where parameter_id = v_parameter_id 
     and package_id is null;
    update apm_parameter_values set attr_value = set_value__attr_value
     where value_id = v_value_id;
    update acs_objects set last_modified = now() 
     where object_id = v_value_id;
   --  exception 
     if NOT FOUND
       then
         v_value_id := apm_parameter_value__new(
            null,
            null,
            v_parameter_id,
            set_value__attr_value
         );
     end if;

    return 0; 
END;
$$ LANGUAGE plpgsql;

--
-- legacy procedure apm__set_value/3
-- Replaced now by apm__set_global_value
---
CREATE OR REPLACE FUNCTION apm__set_value(
   set_value__package_key varchar,
   set_value__parameter_name varchar,
   set_value__attr_value varchar
) RETURNS integer AS $$
BEGIN
    return apm__set_global_value(set_value__package_key, set_value__parameter_name, set_value__attr_value);
END;    
$$ LANGUAGE plpgsql;
