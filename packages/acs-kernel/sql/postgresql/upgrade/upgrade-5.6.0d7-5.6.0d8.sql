
create or replace function apm_package__initialize_parameters (integer,varchar)
returns integer as '
declare
  ip__package_id             alias for $1;  
  ip__package_key            alias for $2;  
  v_value_id                 apm_parameter_values.value_id%TYPE;
  cur_val                    record;
begin
    -- need to initialize all params for this type
    for cur_val in select parameter_id, default_value
       from apm_parameters
       where package_key = ip__package_key
         and scope = ''instance''
      loop
        v_value_id := apm_parameter_value__new(
          null,
          ip__package_id,
          cur_val.parameter_id,
          cur_val.default_value
        ); 
      end loop;   

      return 0; 
end;' language 'plpgsql';

