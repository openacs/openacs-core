alter table acs_datatypes add database_type text;
alter table acs_datatypes add column_size text;
alter table acs_datatypes add column_check_expr text;
alter table acs_datatypes add column_output_function text;

alter table acs_attributes drop constraint acs_attributes_datatype_fk; 
alter table acs_attributes add constraint acs_attributes_datatype_fk 
   foreign key (datatype) 
   references acs_datatypes(datatype) on update cascade;

insert into acs_datatypes
  (datatype, database_type)
(select 'text', 'text' from dual
  where not exists (select 1 from acs_datatypes where datatype = 'text'));

insert into acs_datatypes
  (datatype, database_type)
(select 'richtext', 'text' from dual
  where not exists (select 1 from acs_datatypes where datatype = 'richtext'));

insert into acs_datatypes
  (datatype, database_type, column_size)
(select 'filename', 'varchar', '100' from dual
  where not exists (select 1 from acs_datatypes where datatype = 'filename'));

insert into acs_datatypes
  (datatype, database_type)
(select 'float', 'float8' from dual
  where not exists (select 1 from acs_datatypes where datatype = 'float'));

-- PG 8.x has no unsigned integer datatype
insert into acs_datatypes
  (datatype, database_type)
(select 'naturalnum', 'integer' from dual
  where not exists (select 1 from acs_datatypes where datatype = 'naturalnum'));


-- Making user and person dynamic can lead to a broken web site, so
-- for now at least I won't do it.  Code using these types have assumptions
-- about the existence of certain attributes, and of course deleting them
-- and their objects would destroy a site.

-- Types probably should have a flag saying whether or not it can be deleted, and
-- perhaps attributes, too.  Too much change for now.

-- DAVEB since you can just extend it and create a view on that, that should
-- be plenty of customization. You can just ignore the attributes you aren't
-- interested in

--update acs_object_types
--set dynamic_p = 't'
--where object_type = 'person';

--update acs_object_types
--set dynamic_p = 't'
--where object_type = 'user';

comment on table acs_datatypes is '
 Defines the set of available abstract datatypes for acs_attributes, along with
 an optional default mapping to a database type, size, and constraint to use if the
 attribute is created with create_attribute''s storage_type param set to "type_specific"
 and the create_storage_p param is set to true.  These defaults can be overwritten by
 the caller.

 The set of pre-defined datatypes is inspired by XForms
 (http://www.w3.org/TR/xforms-datamodel/).
';

comment on column acs_datatypes.database_type is '
  The base database type corresponding to the abstract datatype.  For example "varchar" or
  "integer".
';

comment on column acs_datatypes.column_size is '
  Optional default column size specification to append to the base database type.  For
  example "1000" for the "string" abstract datatype, or "10,2" for "number".
';

comment on column acs_datatypes.column_check_expr is '
  Optional check constraint expression to declare for the type_specific database column.  In
  Oracle, for instance, the abstract "boolean" type is declared "text", with a column
  check expression to restrict the values to "f" and "t".
';

comment on column acs_datatypes.column_output_function is '
  Function to call for this datatype when building a select view.  If not null, it will
  be called with an attribute name and is expected to return an expression on that
  attribute.  Example: date attributes will be transformed to calls to "to_char()".
';

-- Though the PostgreSQL "text" type is a true variable length string implementation, we
-- implement most string types using "varchar" and a default size argument.  This makes
-- it possible to write a high-level type specification that works in both Oracle and PG.

-- DRB: add double bigint etc if Oracle supports them
begin;

  update acs_datatypes
  set database_type = 'varchar',
    column_size = '250'
  where datatype = 'url';

  update acs_datatypes
  set database_type = 'varchar',
    column_size = '4000'
  where datatype = 'string';

  update acs_datatypes
  set database_type = 'boolean'
  where datatype = 'boolean';

  update acs_datatypes
  set database_type = 'numeric',
    column_size = '10,2'
  where datatype = 'number';

  update acs_datatypes
  set database_type = 'integer'
  where datatype = 'integer';

  update acs_datatypes 
  set datatype = 'currency'
  where datatype = 'money';

  update acs_datatypes 
  set database_type = 'money'
  where datatype = 'currency';

  update acs_datatypes
  set database_type = 'timestamp'
  where datatype = 'date';

  update acs_datatypes
  set database_type = 'timestamp'
  where datatype = 'timestamp';

  update acs_datatypes
  set database_type = 'timestamp'
  where datatype = 'time_of_day';

  update acs_datatypes
  set database_type = 'varchar',
    column_size = '100'
  where datatype = 'enumeration';

  update acs_datatypes
  set database_type = 'varchar',
    column_size = 200
  where datatype = 'email';

  update acs_datatypes
  set database_type = 'varchar',
    column_size = 200
  where datatype = 'file';

  update acs_datatypes
  set database_type = 'text'
  where datatype = 'text';

  update acs_datatypes
  set database_type = 'varchar',
    column_size = 100
  where datatype = 'keyword';

  update acs_datatypes
  set column_output_function = 'acs_datatype__date_output_function'
  where datatype = 'date';

  update acs_datatypes
  set column_output_function = 'acs_datatype__timestamp_output_function'
  where datatype = 'timestamp';

  update acs_datatypes
  set column_output_function = 'acs_datatype__timestamp_output_function'
  where datatype = 'time_of_day';
end;

create or replace function acs_datatype__date_output_function(text)
returns text as '
declare
  p_attribute_name alias for $1;
begin
  return ''to_char('' || p_attribute_name || '', ''''YYYY-MM-DD'''')'';
end;' language 'plpgsql';

create or replace function acs_datatype__timestamp_output_function(text)
returns text as '
declare
  p_attribute_name alias for $1;
begin
  return ''to_char('' || p_attribute_name || '', ''''YYYY-MM-DD HH24:MI:SS'''')'';
end;' language 'plpgsql';

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

select define_function_args('acs_attribute__create_attribute','object_type,attribute_name,datatype,pretty_name,pretty_plural,table_name,column_name,default_value,min_n_values;1,max_n_values;1,sort_order,storage;type_specific,static_p;f,create_column_p;f,database_type,size,null_p;t,references,check_expr,column_spec');

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
  p_create_column_p        alias for $14;
  p_database_type          alias for $15;
  p_size                   alias for $16;
  p_null_p                 alias for $17;
  p_references             alias for $18;
  p_check_expr             alias for $19;
  p_column_spec            alias for $20;

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
    -- 1. the attribute is declared type_specific (generic storage uses an auxiliary table)
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

-- "cascade_p" corresponds to the more logical "drop_objects_p" in the content repository
-- code.  The name is being kept for backwards compatibilit.

select define_function_args('acs_object_type__drop_type','object_type,cascade_p;f,drop_table_p;f,drop_children_p;f');

-- procedure drop_type
create or replace function acs_object_type__drop_type (varchar,boolean,boolean,boolean)
returns integer as '
declare
  p_object_type                     alias for $1;  
  p_drop_children_p                 alias for $2;
  p_drop_table_p                    alias for $3;
  p_cascade_p                       alias for $4;
  row                               record;
  object_row                        record;
  v_table_name                      acs_object_types.table_name%TYPE;
begin

  -- drop children recursively
  if p_drop_children_p then
    for row in select object_type
               from acs_object_types
               where supertype = p_object_type 
    loop
      perform acs_object_type__drop_type(row.object_type, p_cascade_p, p_drop_table_p, ''t'');
    end loop;
  end if;

  -- drop object rows
  if p_cascade_p then
    for object_row in select object_id
                      from acs_objects
                      where object_type = p_object_type
    loop
      perform acs_object__delete (object_row.object_id);
    end loop;
  end if;

  -- drop all the attributes associated with this type
  for row in select attribute_name 
             from acs_attributes 
             where object_type = p_object_type 
  loop
    perform acs_attribute__drop_attribute (p_object_type, row.attribute_name);
  end loop;

  -- Remove the associated table if it exists and p_drop_table_p is true

  if p_drop_table_p then

    select table_name into v_table_name 
    from acs_object_types 
    where object_type = p_object_type;

    if found then
      if not exists (select 1
                     from pg_class
                     where relname = lower(v_table_name)) then
        raise exception ''Table "%" does not exist'', v_table_name;
      end if;

      execute ''drop table '' || v_table_name || '' cascade'';
    end if;

  end if;

  delete from acs_object_types
  where object_type = p_object_type;

  return 0; 
end;' language 'plpgsql';

-- Retained for backwards compatibility

create or replace function acs_object_type__drop_type (varchar,boolean)
returns integer as '
begin
  return acs_object_type__drop_type($1,$2,''f'',''f'');
end;' language 'plpgsql';

-- procedure drop_attribute
select define_function_args('acs_attribute__drop_attribute','object_type,attribute_name,drop_column_p;f');

create or replace function acs_attribute__drop_attribute (varchar,varchar,boolean)
returns integer as '
declare
  p_object_type            alias for $1;  
  p_attribute_name         alias for $2;  
  p_drop_column_p          alias for $3;
  v_table_name             acs_object_types.table_name%TYPE;
begin

  -- Check that attribute exists and simultaneously grab the type''s table name
  select t.table_name into v_table_name
  from acs_object_types t, acs_attributes a
  where a.object_type = p_object_type
    and a.attribute_name = p_attribute_name
    and t.object_type = p_object_type;
    
  if not found then
    raise exception ''Attribute %:% does not exist'', p_object_type, p_attribute_name;
  end if;

  -- first remove possible values for the enumeration
  delete from acs_enum_values
  where attribute_id in (select a.attribute_id 
                         from acs_attributes a 
                         where a.object_type = p_object_type
                         and a.attribute_name = p_attribute_name);

  -- Drop the table if one were specified for the type and we''re asked to
  if p_drop_column_p and v_table_name is not null then
      execute ''alter table '' || v_table_name || '' drop column '' ||
        p_attribute_name || '' cascade'';
  end if;  

  -- Finally, get rid of the attribute
  delete from acs_attributes
  where object_type = p_object_type
  and attribute_name = p_attribute_name;

  return 0; 
end;' language 'plpgsql';

create or replace function acs_attribute__drop_attribute (varchar,varchar)
returns integer as '
begin
  return acs_attribute__drop_attribute($1, $2, ''f'');
end;' language 'plpgsql';

