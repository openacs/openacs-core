alter table acs_datatypes add database_type varchar(100);
alter table acs_datatypes add column_size varchar(100);
alter table acs_datatypes add column_check_expr varchar(250);
alter table acs_datatypes add column_output_function varchar(100);

insert into acs_datatypes
  (datatype, database_type)
(select 'text', 'clob' from dual
  where not exists (select 1 from acs_datatypes where datatype = 'text'));

insert into acs_datatypes
  (datatype, database_type)
(select 'richtext', 'clob' from dual
  where not exists (select 1 from acs_datatypes where datatype = 'richtext'));

insert into acs_datatypes
  (datatype, database_type, column_size)
(select 'filename', 'varchar', '100' from dual
  where not exists (select 1 from acs_datatypes where datatype = 'filename'));

insert into acs_datatypes
  (datatype, database_type)
(select 'float', 'float' from dual
  where not exists (select 1 from acs_datatypes where datatype = 'float'));

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
 the caller.  The set of pre-defined datatypes is inspired by XForms
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
begin

  update acs_datatypes
  set database_type = 'varchar',
    column_size = '250'
  where datatype = 'url';

  update acs_datatypes
  set database_type = 'varchar',
    column_size = '4000'
  where datatype = 'string';

  update acs_datatypes
  set database_type = 'char',
    column_size = '1',
    column_check_expr = 'in (''t'', ''f''))'
  where datatype = 'boolean';

  update acs_datatypes
  set database_type = 'number',
    column_size = '10,2'
  where datatype = 'number';

  update acs_datatypes
  set database_type = 'integer'
  where datatype = 'integer';

  update acs_datatypes 
  set datatype = 'currency'
  where datatype = 'money';

  update acs_datatypes 
  set database_type = 'number',
    column_size = '10,2'
  where datatype = 'currency';

  update acs_datatypes
  set database_type = 'date'
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
  set database_type = 'clob'
  where datatype = 'text';

  update acs_datatypes
  set database_type = 'varchar',
    column_size = 100
  where datatype = 'keyword';

  update acs_datatypes
  set column_output_function = 'acs_datatype.date_output_function'
  where datatype = 'date';

  update acs_datatypes
  set column_output_function = 'acs_datatype.timestamp_output_function'
  where datatype = 'timestamp';

  update acs_datatypes
  set column_output_function = 'acs_datatype.timestamp_output_function'
  where datatype = 'time_of_day';
end;
/
show errors

create or replace package acs_datatype
is
  function date_output_function(attribute_name in varchar2)
  return acs_datatypes.column_output_function%TYPE;
  function timestamp_output_function(attribute_name in varchar2)
  return acs_datatypes.column_output_function%TYPE;
end acs_datatype;
/
show errors

create or replace package body acs_datatype
is
  function date_output_function(attribute_name in varchar2)
  return acs_datatypes.column_output_function%TYPE
  is
  begin
    return 'to_char(' || attribute_name || ', ''YYYY-MM-DD'')';
  end date_output_function;

  function timestamp_output_function(attribute_name in varchar2)
  return acs_datatypes.column_output_function%TYPE
  is
  begin
    return 'to_char(' || attribute_name || ', ''YYYY-MM-DD HH24:MI::SS'')';
  end timestamp_output_function;

end acs_datatype;
/
show errors

create or replace package acs_object_type
is
  -- define an object type
  procedure create_type (
    object_type		in acs_object_types.object_type%TYPE,
    pretty_name		in acs_object_types.pretty_name%TYPE,
    pretty_plural	in acs_object_types.pretty_plural%TYPE,
    supertype		in acs_object_types.supertype%TYPE
			   default 'acs_object',
    table_name		in acs_object_types.table_name%TYPE default null,
    id_column		in acs_object_types.id_column%TYPE default null,
    package_name	in acs_object_types.package_name%TYPE default null,
    abstract_p		in acs_object_types.abstract_p%TYPE default 'f',
    type_extension_table in acs_object_types.type_extension_table%TYPE
			    default null,
    name_method		in acs_object_types.name_method%TYPE default null,
    create_table_p in varchar2 default 'f',
    dynamic_p in varchar2 default 'f'
  );

  -- delete an object type definition
  procedure drop_type (
    object_type		in acs_object_types.object_type%TYPE,
    drop_children_p in varchar2 default 'f',
    drop_table_p in varchar2 default 'f'
  );

  -- look up an object type's pretty_name
  function pretty_name (
    object_type 	in acs_object_types.object_type%TYPE
  ) return acs_object_types.pretty_name%TYPE;

  -- Returns 't' if object_type_2 is a subtype of object_type_1. Note
  -- that this function will return 'f' if object_type_1 =
  -- object_type_2
  function is_subtype_p (
    object_type_1 	in acs_object_types.object_type%TYPE,
    object_type_2 	in acs_object_types.object_type%TYPE
  ) return char;

end acs_object_type;
/
show errors

create or replace package body acs_object_type
is

  procedure create_type (
    object_type		in acs_object_types.object_type%TYPE,
    pretty_name		in acs_object_types.pretty_name%TYPE,
    pretty_plural	in acs_object_types.pretty_plural%TYPE,
    supertype		in acs_object_types.supertype%TYPE
			   default 'acs_object',
    table_name		in acs_object_types.table_name%TYPE default null,
    id_column		in acs_object_types.id_column%TYPE default null,
    package_name	in acs_object_types.package_name%TYPE default null,
    abstract_p		in acs_object_types.abstract_p%TYPE default 'f',
    type_extension_table in acs_object_types.type_extension_table%TYPE
			    default null,
    name_method		in acs_object_types.name_method%TYPE default null,
    create_table_p in varchar2 default 'f',
    dynamic_p in varchar2 default 'f'
  )
  is
    v_package_name acs_object_types.package_name%TYPE;
    v_table_name	acs_object_types.table_name%TYPE;
    v_id_column	acs_object_types.id_column%TYPE;
    v_supertype	acs_object_types.supertype%TYPE;
    v_supertype_table	acs_object_types.table_name%TYPE;
    v_table_exists integer;
  begin

    if (create_table_p = 't') and (table_name is null or table_name = '') then
      v_table_name := object_type || '_t';
    else
      v_table_name := table_name;
    end if;

    if (create_table_p = 't') and (id_column is null or id_column = '') then
      v_id_column := object_type || '_id';
    else
      v_id_column := id_column;
    end if;

    if package_name is null then
      v_package_name := object_type;
    else
      v_package_name := package_name;
    end if;

    if object_type <> 'acs_object' and (supertype is null or supertype = '') then
      v_supertype := 'acs_object';
    else
      v_supertype := supertype;
    end if;

    insert into acs_object_types
      (object_type, pretty_name, pretty_plural, supertype, table_name,
       id_column, abstract_p, type_extension_table, package_name,
       name_method)
    values
      (object_type, pretty_name, pretty_plural, v_supertype, v_table_name,
       v_id_column, abstract_p, type_extension_table, v_package_name,
       name_method);

    if (create_table_p = 't') then

      select decode(count(*),0,0,1) into v_table_exists from user_tables
        where table_name = upper(v_table_name);

      if v_table_exists = 1 then
        raise_application_error(-20000, 'Table ' || v_table_name || ' already exists.');
      end if;

      loop
        select table_name,object_type into v_supertype_table,v_supertype
        from acs_object_types
        where object_type = v_supertype;
        exit when v_supertype_table is not null;
      end loop;

      execute immediate 'create table ' || v_table_name || ' (' ||
        v_id_column  || ' integer primary key references ' ||
        v_supertype_table || ')';

    end if;

end create_type;

  procedure drop_type (
    object_type		in acs_object_types.object_type%TYPE,
    drop_children_p in varchar2 default 'f',
    drop_table_p in varchar2 default 'f'
  )
  is
    cursor c_attributes (object_type IN varchar) is
      select attribute_name from acs_attributes where object_type = c_attributes.object_type;
    cursor c_subtypes (object_type IN varchar) is
      select object_type from acs_object_types where supertype = c_subtypes.object_type;
    v_table_name acs_object_types.table_name%TYPE;
  begin

    -- drop children recursively
    if drop_children_p = 't' then
      for row in c_subtypes (drop_type.object_type) loop
         drop_type(row.object_type, 't', drop_table_p);
      end loop;
    end if;

    -- drop all the attributes associated with this type
    for row in c_attributes (drop_type.object_type) loop
       acs_attribute.drop_attribute ( drop_type.object_type, row.attribute_name );
    end loop;

    if drop_table_p = 't' then
      select table_name into v_table_name
      from acs_object_types
      where object_type = drop_type.object_type;

      execute immediate 'drop table ' || v_table_name || ' cascade';
    end if;

    delete from acs_object_types
    where object_type = drop_type.object_type;
  end drop_type;


  function pretty_name (
    object_type 	in acs_object_types.object_type%TYPE 
  ) return acs_object_types.pretty_name%TYPE
  is
    v_pretty_name       acs_object_types.pretty_name%TYPE;
  begin
    select t.pretty_name into v_pretty_name
      from acs_object_types t
     where t.object_type = pretty_name.object_type;

    return v_pretty_name;

  end pretty_name;


  function is_subtype_p (
    object_type_1 	in acs_object_types.object_type%TYPE,
    object_type_2 	in acs_object_types.object_type%TYPE
  ) return char
  is 
    v_result integer;
  begin
    select count(*) into v_result
      from dual
     where exists (select 1 
                     from acs_object_types t 
                    where t.object_type	= is_subtype_p.object_type_2
                  connect by prior t.object_type = t.supertype
                    start with t.supertype = is_subtype_p.object_type_1);

    if v_result > 0 then
       return 't';
    end if;

    return 'f';

   end is_subtype_p;

end acs_object_type;
/
show errors

create or replace package acs_attribute
is

  -- define an object attribute
  function create_attribute (
    object_type		in acs_attributes.object_type%TYPE,
    attribute_name	in acs_attributes.attribute_name%TYPE,
    datatype		in acs_attributes.datatype%TYPE,
    pretty_name		in acs_attributes.pretty_name%TYPE,
    pretty_plural	in acs_attributes.pretty_plural%TYPE default null,
    table_name		in acs_attributes.table_name%TYPE default null,
    column_name		in acs_attributes.column_name%TYPE default null,
    default_value	in acs_attributes.default_value%TYPE default null,
    min_n_values	in acs_attributes.min_n_values%TYPE default 1,
    max_n_values	in acs_attributes.max_n_values%TYPE default 1,
    sort_order		in acs_attributes.sort_order%TYPE default null,
    storage		in acs_attributes.storage%TYPE default 'type_specific',
    static_p		in acs_attributes.static_p%TYPE default 'f',
    create_column_p in varchar2 default 'f',
    database_type in acs_datatypes.database_type%TYPE default null,
    column_size in acs_datatypes.column_size%TYPE default null,
    null_p in varchar2 default 't',
    references in varchar2 default null,
    check_expr in acs_datatypes.column_check_expr%TYPE default null,
    column_spec in varchar2 default null
  ) return acs_attributes.attribute_id%TYPE;

  procedure drop_attribute (
    object_type in varchar2,
    attribute_name in varchar2,
    drop_column_p in varchar2 default 'f'
  );

  procedure add_description (
    object_type		in acs_attribute_descriptions.object_type%TYPE,
    attribute_name	in acs_attribute_descriptions.attribute_name%TYPE,
    description_key	in acs_attribute_descriptions.description_key%TYPE,
    description		in acs_attribute_descriptions.description%TYPE
  );

  procedure drop_description (
    object_type		in acs_attribute_descriptions.object_type%TYPE,
    attribute_name	in acs_attribute_descriptions.attribute_name%TYPE,
    description_key	in acs_attribute_descriptions.description_key%TYPE
  );

end acs_attribute;
/
show errors

create or replace package body acs_attribute
is

  function create_attribute (
    object_type		in acs_attributes.object_type%TYPE,
    attribute_name	in acs_attributes.attribute_name%TYPE,
    datatype		in acs_attributes.datatype%TYPE,
    pretty_name		in acs_attributes.pretty_name%TYPE,
    pretty_plural	in acs_attributes.pretty_plural%TYPE default null,
    table_name		in acs_attributes.table_name%TYPE default null,
    column_name		in acs_attributes.column_name%TYPE default null,
    default_value	in acs_attributes.default_value%TYPE default null,
    min_n_values	in acs_attributes.min_n_values%TYPE default 1,
    max_n_values	in acs_attributes.max_n_values%TYPE default 1,
    sort_order		in acs_attributes.sort_order%TYPE default null,
    storage		in acs_attributes.storage%TYPE default 'type_specific',
    static_p		in acs_attributes.static_p%TYPE default 'f',
    create_column_p in varchar2 default 'f',
    database_type in acs_datatypes.database_type%TYPE default null,
    column_size in acs_datatypes.column_size%TYPE default null,
    null_p in varchar2 default 't',
    references in varchar2 default null,
    check_expr in acs_datatypes.column_check_expr%TYPE default null,
    column_spec in varchar2 default null
  ) return acs_attributes.attribute_id%TYPE
  is
    type datatype_type is record (
        database_type acs_datatypes.database_type%TYPE,
        column_size acs_datatypes.column_size%TYPE,
        column_check_expr acs_datatypes.column_check_expr%TYPE);
    v_sort_order acs_attributes.sort_order%TYPE;
    v_attribute_id    acs_attributes.attribute_id%TYPE;
    v_column_spec varchar2(4000);
    v_table_name acs_attributes.table_name%TYPE;
    v_constraint_stub varchar2(4000);
    v_column_name acs_attributes.column_name%TYPE;
    v_type_exists integer;
    v_table_exists integer;
    v_column_exists integer;
    v_datatype datatype_type;
  begin

    select decode(count(*),0,0,1) into v_type_exists
    from acs_object_types
    where object_type = create_attribute.object_type;
    if v_type_exists = 0 then
      raise_application_error(-20000, object_type || ' does not exist');
    end if;

    if sort_order is null then
      select nvl(max(sort_order), 1) into v_sort_order
      from acs_attributes
      where object_type = create_attribute.object_type
      and attribute_name = create_attribute.attribute_name;
    else
      v_sort_order := sort_order;
    end if;

    select acs_attribute_id_seq.nextval into v_attribute_id from dual;

    insert into acs_attributes
      (attribute_id, object_type, table_name, column_name, attribute_name,
       pretty_name, pretty_plural, sort_order, datatype, default_value,
       min_n_values, max_n_values, storage, static_p)
    values
      (v_attribute_id, object_type, table_name, column_name, attribute_name,
       pretty_name, pretty_plural, v_sort_order, datatype, default_value,
       min_n_values, max_n_values, storage, static_p);

    if create_column_p = 't' then

      select table_name into v_table_name
      from acs_object_types
      where object_type = create_attribute.object_type;

      select decode(count(*),0,0,1) into v_table_exists
      from user_tables
      where table_name = upper(v_table_name);

      if v_table_exists = 0 then
        raise_application_error(-20000, 'Table ' || v_table_name || ' does not exists.');
      end if;

      -- Add the appropriate column to the table

      -- We can only create the table column if
      -- 1. the attribute is declared type_specific (generic storage uses an auxiliary table)
      -- 2. the attribute is not declared static
      -- 3. it does not already exist in the table

      if storage <> 'type_specific' then
        raise_application_error(-20000, 'Attribute ' || attribute_name || ' for object type ' || object_type || ' must be declared with type_specific storage');
      end if;

      if static_p = 't' then
        raise_application_error(-20000, 'Attribute ' || attribute_name || ' for object type ' || object_type || ' can not be declared static');
      end if;

      if table_name is not null then
        raise_application_error(-20000, 'Attribute ' || attribute_name || ' for object type ' || object_type || ' can not specify a table for storage');
      end if;

      select decode(count(*),0,0,1) into v_column_exists
      from user_tab_columns
      where table_name = upper(v_table_name)
        and column_name = upper(attribute_name);

      if v_column_exists = 1 then
        raise_application_error(-20000, 'Column ' || attribute_name || ' for object type ' || object_type || ' already exists');
      end if;

      -- all conditions for creating this column have been met, now let''s see if the type
      -- spec is OK

      if column_spec is not null then
        if database_type is not null
          or column_size is not null
          or null_p is not null
          or references is not null
          or check_expr is not null then
        raise_application_error(-20000, 'Attribute ' || attribute_name || ' for object type ' || object_type || ' is being created with an explicit column_spec, but not all of the type modification fields are null');
        end if;
        v_column_spec := column_spec;
      else
        select coalesce(create_attribute.database_type, database_type) as database_type,
          coalesce(create_attribute.column_size, column_size) as column_size,
          coalesce(check_expr, column_check_expr) as column_check_expr
        into v_datatype
        from acs_datatypes
        where datatype = create_attribute.datatype;

        v_column_spec := v_datatype.database_type;

        if v_datatype.column_size is not null then
          v_column_spec := v_column_spec || '(' || v_datatype.column_size || ')';
        end if;

        v_constraint_stub := ' constraint ' || object_type || '_' ||
          attribute_name || '_';

        if v_datatype.column_check_expr is not null then
          v_column_spec := v_column_spec || v_constraint_stub || 'ck check(' ||
          attribute_name || v_datatype.column_check_expr || ')';
        end if;

        if null_p = 'f' then
          v_column_spec := v_column_spec || v_constraint_stub || 'nn not null';
        end if;

        if references is not null then
          v_column_spec := v_column_spec || v_constraint_stub || 'fk references ' ||
          references || ' on delete';
          if null_p = 't' then
            v_column_spec := v_column_spec || ' set null';
          else
            v_column_spec := v_column_spec || ' cascade';
          end if;
        end if;

      end if;

      execute immediate 'alter table ' || v_table_name || ' add ' || 
        attribute_name || ' ' || v_column_spec;
    end if;

    return v_attribute_id;
  end create_attribute;

  procedure drop_attribute (
    object_type in varchar2,
    attribute_name in varchar2,
    drop_column_p in varchar2 default 'f'
  )
  is
  begin
    -- first remove possible values for the enumeration
    delete from acs_enum_values
      where attribute_id in (select a.attribute_id 
                               from acs_attributes a 
                              where a.object_type = drop_attribute.object_type
                                and a.attribute_name = drop_attribute.attribute_name);

    delete from acs_attributes
     where object_type = drop_attribute.object_type
       and attribute_name = drop_attribute.attribute_name;
  end drop_attribute;

  procedure add_description (
    object_type		in acs_attribute_descriptions.object_type%TYPE,
    attribute_name	in acs_attribute_descriptions.attribute_name%TYPE,
    description_key	in acs_attribute_descriptions.description_key%TYPE,
    description		in acs_attribute_descriptions.description%TYPE
  )
  is
  begin
    insert into acs_attribute_descriptions
     (object_type, attribute_name, description_key, description)
    values
     (add_description.object_type, add_description.attribute_name,
      add_description.description_key, add_description.description);
  end;

  procedure drop_description (
    object_type		in acs_attribute_descriptions.object_type%TYPE,
    attribute_name	in acs_attribute_descriptions.attribute_name%TYPE,
    description_key	in acs_attribute_descriptions.description_key%TYPE
  )
  is
  begin
    delete from acs_attribute_descriptions
    where object_type = drop_description.object_type
    and attribute_name = drop_description.attribute_name
    and description_key = drop_description.description_key;
  end;

end acs_attribute;
/
show errors
