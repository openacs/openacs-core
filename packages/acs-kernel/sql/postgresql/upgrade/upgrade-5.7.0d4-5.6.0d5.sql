select define_function_args('acs_object_type__create_type','object_type,pretty_name,pretty_plural,supertype,table_name,id_column,package_name,abstract_p;f,type_extension_table,name_method,create_table_p;f,dynamic_p;f');

create or replace function acs_object_type__create_type (varchar,varchar,varchar,varchar,varchar,varchar,varchar,boolean,varchar,varchar, boolean, boolean)
returns integer as '
declare
  p_object_type            alias for $1;  
  p_pretty_name            alias for $2;  
  p_pretty_plural          alias for $3;  
  p_supertype              alias for $4;  
  p_table_name             alias for $5;  -- default null
  p_id_column              alias for $6;  -- default null
  p_package_name           alias for $7;  -- default null
  p_abstract_p             alias for $8;  -- default ''f''
  p_type_extension_table   alias for $9;  -- default null
  p_name_method            alias for $10; -- default null
  p_create_table_p         alias for $11;
  p_dynamic_p              alias for $12;
  v_package_name                      acs_object_types.package_name%TYPE;
  v_supertype                         acs_object_types.supertype%TYPE;
  v_name_method                       varchar;
  v_idx                               integer;
  v_temp_p                            boolean;
  v_supertype_table                   acs_object_types.table_name%TYPE;
  v_id_column                         acs_object_types.id_column%TYPE;
  v_table_name                        acs_object_types.table_name%TYPE;
begin
    v_idx := position(''.'' in p_name_method);
    if v_idx <> 0 then
         v_name_method := substr(p_name_method,1,v_idx - 1) || 
                       ''__'' || substr(p_name_method, v_idx + 1);
    else 
         v_name_method := p_name_method;
    end if;

    -- If we are asked to create the table, provide reasonable default values for the
    -- table name and id column.  Traditionally OpenACS uses the plural form of the type
    -- name.  This code appends "_t" (for "table") because the use of english plural rules
    -- does not work well for all languages.

    if p_create_table_p and (p_table_name is null or p_table_name = '''') then
      v_table_name := p_object_type || ''_t'';
    else
      v_table_name := p_table_name;
    end if;

    if p_create_table_p and (p_id_column is null or p_id_column = '''') then
      v_id_column := p_object_type || ''_id'';
    else
      v_id_column := p_id_column;
    end if;

    if p_package_name is null or p_package_name = '''' then
      v_package_name := p_object_type;
    else
      v_package_name := p_package_name;
    end if;

    if p_supertype is null or p_supertype = '''' then
      v_supertype := ''acs_object'';
    else
      v_supertype := p_supertype;
      if not acs_object_type__is_subtype_p(''acs_object'', p_supertype)
      then
        raise exception ''%s is not a valid type'', p_supertype;
      end if;
    end if;

    insert into acs_object_types
      (object_type, pretty_name, pretty_plural, supertype, table_name,
       id_column, abstract_p, type_extension_table, package_name,
       name_method, dynamic_p)
    values
      (p_object_type, p_pretty_name, 
       p_pretty_plural, v_supertype, 
       v_table_name, v_id_column, 
       p_abstract_p, p_type_extension_table, 
       v_package_name, v_name_method, p_dynamic_p);

    if p_create_table_p then

      if exists (select 1
                 from pg_class
                 where relname = lower(v_table_name)) then
        raise exception ''Table "%" already exists'', v_table_name;
      end if;

      select table_name into v_supertype_table from acs_object_types
      where object_type = p_supertype;
  
      execute ''create table '' || v_table_name || '' ('' ||
        v_id_column || '' integer constraint '' || v_table_name ||
        ''_pk primary key '' || '' constraint '' || v_table_name ||
        ''_fk references '' || v_supertype_table || '' on delete cascade)'';
    end if;

    return 0; 
end;' language 'plpgsql';

-- DRB: backwards compatibility version, don't allow for table creation.

create or replace function acs_object_type__create_type (varchar,varchar,varchar,varchar,varchar,varchar,varchar,boolean,varchar,varchar)
returns integer as '
declare
  p_object_type            alias for $1;  
  p_pretty_name            alias for $2;  
  p_pretty_plural          alias for $3;  
  p_supertype              alias for $4;  
  p_table_name             alias for $5;  -- default null
  p_id_column              alias for $6;  -- default null
  p_package_name           alias for $7;  -- default null
  p_abstract_p             alias for $8;  -- default ''f''
  p_type_extension_table   alias for $9;  -- default null
  p_name_method            alias for $10; -- default null
begin
    return acs_object_type__create_type(p_object_type, p_pretty_name,
      p_pretty_plural, p_supertype, p_table_name,
      p_id_column, p_package_name, p_abstract_p,
      p_type_extension_table, p_name_method,''f'',''f'');
end;' language 'plpgsql';
