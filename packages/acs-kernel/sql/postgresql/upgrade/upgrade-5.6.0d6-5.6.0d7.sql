
alter table apm_parameters add scope varchar(10) default 'instance' check (scope in ('global','instance')) not null;

begin;
 select acs_attribute__create_attribute (
   'apm_parameter',
   'scope',
   'string',
   'Scope',
   'Scope',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   ) from dual;
end;

drop function apm__get_value (integer,integer);
drop function apm__set_value (integer,integer,varchar);

create or replace function apm__register_parameter (integer,varchar,varchar,varchar,varchar,varchar,varchar,varchar,integer,integer)
returns integer as '
declare
  register_parameter__parameter_id           alias for $1;  -- default null  
  register_parameter__package_key            alias for $2;  
  register_parameter__parameter_name         alias for $3;  
  register_parameter__description            alias for $4;  -- default null  
  register_parameter__scope                  alias for $5;  
  register_parameter__datatype               alias for $6;  -- default ''string''  
  register_parameter__default_value          alias for $7;  -- default null  
  register_parameter__section_name           alias for $8;  -- default null 
  register_parameter__min_n_values           alias for $9;  -- default 1
  register_parameter__max_n_values           alias for $10;  -- default 1

  v_parameter_id         apm_parameters.parameter_id%TYPE;
  v_value_id             apm_parameter_values.value_id%TYPE;
  v_pkg                  record;

begin
    -- Create the new parameter.    
    v_parameter_id := acs_object__new(
       register_parameter__parameter_id,
       ''apm_parameter'',
       now(),
       null,
       null,
       null,
       ''t'',
       register_parameter__package_key || '' - '' || register_parameter__parameter_name,
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
    if register_parameter__scope = ''instance'' then
      for v_pkg in
          select package_id
  	from apm_packages
  	where package_key = register_parameter__package_key
        loop
        	v_value_id := apm_parameter_value__new(
  	    null,
  	    v_pkg.package_id,
  	    v_parameter_id, 
  	    register_parameter__default_value
  	    ); 	
        end loop;		
     else
       v_value_id := apm_parameter_value__new(
  	 null,
  	 null,
  	 v_parameter_id, 
  	 register_parameter__default_value); 	
    end if;
	
    return v_parameter_id;
   
end;' language 'plpgsql';

-- For backwards compatibility, register a parameter with "instance" scope.

create or replace function apm__register_parameter (integer,varchar,varchar,varchar,varchar,varchar,varchar,integer,integer)
returns integer as '
declare
  register_parameter__parameter_id           alias for $1;  -- default null  
  register_parameter__package_key            alias for $2;  
  register_parameter__parameter_name         alias for $3;  
  register_parameter__description            alias for $4;  -- default null  
  register_parameter__datatype               alias for $5;  -- default ''string''  
  register_parameter__default_value          alias for $6;  -- default null  
  register_parameter__section_name           alias for $7;  -- default null 
  register_parameter__min_n_values           alias for $8;  -- default 1
  register_parameter__max_n_values           alias for $9;  -- default 1

begin
  return
    apm__register_parameter(register_parameter__parameter_id, register_parameter__package_key,
                           register_parameter__parameter_name, register_parameter__description,
                           ''instance'', register_parameter__datatype,
                           register_parameter__default_value, register_parameter__section_name,
                           register_parameter__min_n_values, register_parameter__max_n_values);
end;' language 'plpgsql';

create or replace function apm__id_for_name (integer,varchar)
returns integer as '
declare
  id_for_name__package_id             alias for $1;  
  id_for_name__parameter_name         alias for $2;  
  a_parameter_id                      apm_parameters.parameter_id%TYPE;
begin
    select parameter_id into a_parameter_id 
    from apm_parameters 
    where parameter_name = id_for_name__parameter_name
      and package_key = (select package_key from apm_packages
                         where package_id = id_for_name__package_id);

    if NOT FOUND
      then
      	raise EXCEPTION ''-20000: The specified package % AND/OR parameter % do not exist in the system'', id_for_name__package_id, id_for_name__parameter_name;
    end if;

    return a_parameter_id;
   
end;' language 'plpgsql' stable strict;

create or replace function apm__id_for_name (varchar,varchar)
returns integer as '
declare
  id_for_name__package_key            alias for $1;  
  id_for_name__parameter_name         alias for $2;  
  a_parameter_id                      apm_parameters.parameter_id%TYPE;
begin
    select parameter_id into a_parameter_id
    from apm_parameters p
    where p.parameter_name = id_for_name__parameter_name and
          p.package_key = id_for_name__package_key;

    if NOT FOUND
      then
      	raise EXCEPTION ''-20000: The specified package % AND/OR parameter % do not exist in the system'', id_for_name__package_key, id_for_name__parameter_name;
    end if;

    return a_parameter_id;
   
end;' language 'plpgsql' stable strict;

create or replace function apm__get_value (integer,varchar)
returns varchar as '
declare
  get_value__package_id             alias for $1;  
  get_value__parameter_name         alias for $2;  
  v_parameter_id                    apm_parameter_values.parameter_id%TYPE;
  value                             apm_parameter_values.attr_value%TYPE;
begin
    v_parameter_id := apm__id_for_name (get_value__package_id, get_value__parameter_name);

    select attr_value into value from apm_parameter_values v
    where v.package_id = get_value__package_id
    and parameter_id = get_value__parameter_id;

    return value;
   
end;' language 'plpgsql' stable strict;


create or replace function apm__get_value (varchar,varchar)
returns varchar as '
declare
  get_value__package_key            alias for $1;  
  get_value__parameter_name         alias for $2;  
  v_parameter_id                    apm_parameter_values.parameter_id%TYPE;
  value                             apm_parameter_values.attr_value%TYPE;
begin
    v_parameter_id := apm__id_for_name (get_value__package_key, get_value__parameter_name);

    select attr_value into value from apm_parameter_values v
    where v.package_id = get_value__package_id
    and parameter_id = get_value__parameter_id;

    return value;
   
end;' language 'plpgsql' stable strict;

create or replace function apm__set_value (integer,varchar,varchar)
returns integer as '
declare
  set_value__package_id             alias for $1;  
  set_value__parameter_name         alias for $2;  
  set_value__attr_value             alias for $3;  
  v_parameter_id                    apm_parameter_values.parameter_id%TYPE;
  v_value_id                        apm_parameter_values.value_id%TYPE;
begin
    v_parameter_id := apm__id_for_name (set_value__package_id, set_value__parameter_name);

    -- Determine if the value exists
    select value_id into v_value_id from apm_parameter_values 
     where parameter_id = v_parameter_id 
     and package_id = set_value__package_id;
    update apm_parameter_values set attr_value = set_value__attr_value
     where value_id = v_value_id;
    update acs_objects set last_modified = now() 
     where object_id = v_value_id;
   --  exception 
     if NOT FOUND
       then
         v_value_id := apm_parameter_value__new(
            null,
            set_value__package_id,
            v_parameter_id,
            set_value__attr_value
         );
     end if;

    return 0; 
end;' language 'plpgsql';

create or replace function apm__set_value (varchar,varchar,varchar)
returns integer as '
declare
  set_value__package_key            alias for $1;  
  set_value__parameter_name         alias for $2;  
  set_value__attr_value             alias for $3;  
  v_parameter_id                    apm_parameter_values.parameter_id%TYPE;
  v_value_id                        apm_parameter_values.value_id%TYPE;
begin
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
end;' language 'plpgsql';

