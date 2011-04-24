
create or replace function acs_attribute__create_attribute (varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,integer,integer,integer,varchar,boolean,boolean,varchar,varchar,boolean,varchar,varchar,varchar)
returns integer as '
declare
  p_object_type            alias for $1;  
  p_attribute_name         alias for $2;  
  p_datatype               alias for $3;  
  p_pretty_name            alias for $4;  
  p_pretty_plural          alias for $5;  -- default null
  p_table_name             alias for $6;  -- default null
  p_column_name            alias for $7;  -- default null
  p_default_value          alias for $8;  -- default null
  p_min_n_values           alias for $9;  -- default 1
  p_max_n_values           alias for $10; -- default 1
  p_sort_order             alias for $11; -- default null
  p_storage                alias for $12; -- default ''type_specific''
  p_static_p               alias for $13; -- default ''f''
  p_create_column_p        alias for $14; -- default ''f''
  p_database_type          alias for $15; -- default null
  p_size                   alias for $16; -- default null
  p_null_p                 alias for $17; -- default ''t''
  p_references             alias for $18; -- default null
  p_check_expr             alias for $19; -- default null
  p_column_spec            alias for $20; -- default null

  v_sort_order            acs_attributes.sort_order%TYPE;
  v_attribute_id          acs_attributes.attribute_id%TYPE;
  v_column_spec           text;
  v_table_name            text;
  v_constraint_stub       text;
  v_column_name           text;
  v_datatype              record;

begin

  if not exists (select 1
                 from acs_object_types
                 where object_type = p_object_type) then
    raise exception ''Object type % does not exist'', p_object_type;
  end if; 

  if p_sort_order is null then
    select coalesce(max(sort_order), 1) into v_sort_order
    from acs_attributes
    where object_type = p_object_type
    and attribute_name = p_attribute_name;
  else
    v_sort_order := p_sort_order;
  end if;

  select nextval(''t_acs_attribute_id_seq'') into v_attribute_id;

  insert into acs_attributes
    (attribute_id, object_type, table_name, column_name, attribute_name,
     pretty_name, pretty_plural, sort_order, datatype, default_value,
     min_n_values, max_n_values, storage, static_p)
  values
    (v_attribute_id, p_object_type, 
     p_table_name, p_column_name, 
     p_attribute_name, p_pretty_name,
     p_pretty_plural, v_sort_order, 
     p_datatype, p_default_value,
     p_min_n_values, p_max_n_values, 
     p_storage, p_static_p);

  if p_create_column_p then

    select table_name into v_table_name from acs_object_types
    where object_type = p_object_type;

    if not exists (select 1
                   from pg_class
                   where relname = lower(v_table_name)) then
      raise exception ''Table % for object type % does not exist'', v_table_name, p_object_type;
    end if;

    -- Add the appropriate column to the table

    -- We can only create the table column if
    -- 1. the attribute is declared type_specific (generic storage uses an auxillary table)
    -- 2. the attribute is not declared static
    -- 3. it does not already exist in the table

    if p_storage <> ''type_specific'' then
      raise exception ''Attribute % for object type % must be declared with type_specific storage'',
        p_attribute_name, p_object_type;
    end if;

    if p_static_p then
      raise exception ''Attribute % for object type % can not be declared static'',
        p_attribute_name, p_object_type;
    end if;

    if p_table_name is not null then
      raise exception ''Attribute % for object type % can not specify a table for storage'', p_attribute_name, p_object_type;
    end if;

    if exists (select 1
               from pg_class c, pg_attribute a
               where c.relname::varchar = v_table_name
                 and c.oid = a.attrelid
                 and a.attname = lower(p_attribute_name)) then
      raise exception ''Column % for object type % already exists'',
        p_attribute_name, p_object_type;
    end if;

    -- all conditions for creating this column have been met, now let''s see if the type
    -- spec is OK

    if p_column_spec is not null then
      if p_database_type is not null
        or p_size is not null
        or p_null_p is not null
        or p_references is not null
        or p_check_expr is not null then
      raise exception ''Attribute % for object type % is being created with an explicit column_spec, but not all of the type modification fields are null'',
        p_attribute_name, p_object_type;
      end if;
      v_column_spec := p_column_spec;
    else
      select coalesce(p_database_type, database_type) as database_type,
        coalesce(p_size, column_size) as column_size,
        coalesce(p_check_expr, column_check_expr) as check_expr
      into v_datatype
      from acs_datatypes
      where datatype = p_datatype;
  
      v_column_spec := v_datatype.database_type;

      if v_datatype.column_size is not null then
        v_column_spec := v_column_spec || ''('' || v_datatype.column_size || '')'';
      end if;

      v_constraint_stub := '' constraint '' || p_object_type || ''_'' ||
        p_attribute_name || ''_'';

      if v_datatype.check_expr is not null then
        v_column_spec := v_column_spec || v_constraint_stub || ''ck check('' ||
          p_attribute_name || v_datatype.check_expr || '')'';
      end if;

      if not p_null_p then
        v_column_spec := v_column_spec || v_constraint_stub || ''nn not null'';
      end if;

      if p_references is not null then
        v_column_spec := v_column_spec || v_constraint_stub || ''fk references '' ||
          p_references || '' on delete'';
        if p_null_p then
          v_column_spec := v_column_spec || '' set null'';
        else
          v_column_spec := v_column_spec || '' cascade'';
        end if;
      end if;

    end if;
        
    execute ''alter table '' || v_table_name || '' add '' || p_attribute_name || '' '' ||
            v_column_spec;

  end if;

  return v_attribute_id;

end;' language 'plpgsql';

create or replace function acs_attribute__create_attribute (varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,integer,integer,integer,varchar,boolean)
returns integer as '
declare
  p_object_type            alias for $1;  
  p_attribute_name         alias for $2;  
  p_datatype               alias for $3;  
  p_pretty_name            alias for $4;  
  p_pretty_plural          alias for $5;  -- default null
  p_table_name             alias for $6;  -- default null
  p_column_name            alias for $7;  -- default null
  p_default_value          alias for $8;  -- default null
  p_min_n_values           alias for $9;  -- default 1
  p_max_n_values           alias for $10; -- default 1
  p_sort_order             alias for $11; -- default null
  p_storage                alias for $12; -- default ''type_specific''
  p_static_p               alias for $13; -- default ''f''
begin
  return acs_attribute__create_attribute(p_object_type,
    p_attribute_name, p_datatype, p_pretty_name,
    p_pretty_plural, p_table_name, p_column_name,
    p_default_value, p_min_n_values,
    p_max_n_values, p_sort_order, p_storage,
    p_static_p, ''f'', null, null, null, null, null, null);
end;' language 'plpgsql';

create or replace function acs_attribute__create_attribute (varchar,varchar,varchar,varchar,varchar,varchar,varchar,integer,integer,integer,integer,varchar,boolean)
returns integer as '
begin
    return acs_attribute__create_attribute ($1, $2, $3, $4, $5, $6, $7, cast ($8 as varchar), $9, $10, $11, $12, $13);
end;' language 'plpgsql';

