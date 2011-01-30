alter table acs_datatypes add database_type text;
alter table acs_datatypes add column_size text;
alter table acs_datatypes add column_check_expr text;
alter table acs_datatypes add column_output_function text;

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

-- New tables to model object-based views.  Since view names must be unique in SQL
-- we force them to be unique in our datamodel, too (rather than only unique to the
-- object type). 

create table acs_views (
  object_view    text
                 constraint acs_views__pk
                 primary key,
  object_type    text
                 constraint acs_views_object_type_fk
                 references acs_object_types
                 on delete cascade,
  pretty_name    text
                 constraint acs_views_pretty_name_nn
                 not null,
  root_view_p    boolean default 'f'
                 constraint acs_views_root_view_p_nn
                 not null
);

comment on table acs_views is '
  Track information on object type-based views, including the initial view created for
  an object type
';

comment on column acs_views.object_view is '
  The name of the view.  The initial view for an object type is given the name
  "object_type_name_v".  If the object type the view references is deleted, the acs_view
  will be dropped, too.
';

comment on column acs_views.object_type is '
  The object type this view is built from.
';

comment on column acs_views.pretty_name is '
  Pretty name for this view
';

create table acs_view_attributes (
  attribute_id   integer
                 constraint acs_view_attributes_attribute_id_fk
                 references acs_attributes
                 on delete cascade,
  view_attribute       text,
  object_view    text
                 constraint acs_view_attributes_object_view_fk
                 references acs_views(object_view)
                 on delete cascade,
  pretty_name    text
                 constraint acs_views_pretty_name_nn
                 not null,
  sort_order     integer
                 constraint acs_views_sort_order
                 not null,
  col_expr       text
                 constraint acs_view_attributes_type_col_spec_nn
                 not null,
  constraint acs_view_attributes_pk primary key (object_view, attribute_id)
);

comment on table acs_view_attributes is '
  Track information on view attributes.  This extends the acs_attributes table with
  view-specific attribute information.  If the view or object type attribute referenced
  by the view attribute is deleted, the view attribute will be, too.
';

comment on column acs_view_attributes.attribute_id is '
  The acs_attributes row we are augmenting with view-specific information.  This is not
  used as the primary key because multiple views might use the same acs_attribute.
';

comment on column acs_view_attributes.view_attribute is '
  The name assigned to this column in the view.  Usually it is the acs_attribute name,
  but if multiple attributes have the same name, they are disambiguated with suffixes
  of the form _N.
';

comment on column acs_view_attributes.object_view is '
  The name of the view this attribute is being declared for.
';

comment on column acs_view_attributes.pretty_name is '
  The pretty name of the view.
';

comment on column acs_view_attributes.sort_order is '
  The order of display when shown to a user.  A bit odd to have it here, but
  the original object attributes have a sort_order defined, so for consistency we will
  do the same for view attributes.
';

comment on column acs_view_attributes.col_expr is '
  The expression used to build the column.  Usually just the acs_attribute name, but certain
  datatypes might call a function on the attribute value (i.e. "to_char()" for timestamp
  types).
';

select define_function_args('acs_view__drop_sql_view','object_view');

create or replace function acs_view__drop_sql_view (varchar)
returns integer as '
declare
  p_view                               alias for $1;  
begin
  if table_exists(p_view) then
    execute ''drop view '' || p_view;
  end if;
  return 0;
end;' language 'plpgsql';

select define_function_args('acs_view__create_sql_view','object_view');

create or replace function acs_view__create_sql_view (varchar)
returns integer as '
declare
  p_view                               alias for $1;  
  v_cols                               varchar; 
  v_tabs                               varchar; 
  v_joins                              varchar;
  v_first_p                            boolean;
  v_join_rec                           record;
  v_attr_rec                           record;
  v_tree_sortkey_found_p               boolean;
begin

  if length(p_view) > 64 then
    raise exception ''View name "%" cannot be longer than 64 characters.'',p_type;
  end if;

  if not exists (select 1
                 from acs_views
                 where object_view = p_view) then
    raise exception ''No object type named "%" exists'',p_view;
  end if;

  v_tabs := '''';
  v_joins := '''';
  v_first_p := ''t'';
  v_tree_sortkey_found_p := ''f'';
  v_cols := ''acs_objects.object_id as '' || p_view || ''_id'';

  for v_join_rec in select ot2.object_type, ot2.table_name, ot2.id_column,
                    tree_level(ot2.tree_sortkey) as level
                  from acs_object_types ot1, acs_object_types ot2, acs_views ov
                  where ov.object_view = p_view
                    and ot1.object_type = ov.object_type
                    and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
                  order by ot2.tree_sortkey desc
  loop
    if v_join_rec.table_name is not null then

      if not v_tree_sortkey_found_p and column_exists(v_join_rec.table_name, ''tree_sortkey'') then
        v_cols := v_cols || '','' || v_join_rec.table_name || ''.tree_sortkey'';
        v_tree_sortkey_found_p := ''t'';
      end if;

      if not v_first_p then
        v_tabs := v_tabs || '', '';
      end if;
      v_tabs := v_tabs || v_join_rec.table_name;

      
      if v_join_rec.table_name <> ''acs_objects'' then
        if not v_first_p then
          v_joins := v_joins || '' and '';
        end if;
        v_joins := v_joins || '' acs_objects.object_id = '' || v_join_rec.table_name ||
                   ''.'' || v_join_rec.id_column;
      end if;

      v_first_p := ''f'';

    end if;
  end loop;

  for v_attr_rec in select view_attribute, col_expr
                    from acs_view_attributes
                    where object_view = p_view
                    order by sort_order
  loop
    v_cols := v_cols || '','' || v_attr_rec.col_expr || '' as '' || v_attr_rec.view_attribute;
  end loop;

  if v_joins <> '''' then
    v_joins := '' where '' || v_joins;
  end if;

  if table_exists(p_view) then
    execute ''drop view '' || p_view;
  end if;

  execute ''create or replace view '' || p_view || '' as select '' || 
    v_cols || '' from '' || v_tabs || v_joins;

  return 0; 
end;' language 'plpgsql';

-- Create the attributes select view for a type.  The view is given the type's table
-- name appended with "v".  The only id column returned is object_id, which avoids duplicate
-- column name issues.

select define_function_args('acs_object_type__refresh_view','object_type');

-- Need to create the view and view attribute metadata ...

create or replace function acs_object_type__refresh_view (varchar)
returns integer as '
declare
  p_type                               alias for $1;  
  v_attr_rec                           record;
  v_type_rec                           record;
  v_dupes                              integer;
  v_view_attribute                           text;
  v_col_expr                           text;
  v_sort_order                         integer;
  v_view                               text;
begin

  if not exists (select 1
                 from acs_object_types
                 where object_type = p_type) then
    raise exception ''No object type named "%" exists'',p_type;
  end if;

  v_view := replace(p_type, '':'', ''_'') || ''_v'';

  delete from acs_views where object_view = v_view;

  insert into acs_views
    (object_view, object_type, pretty_name, root_view_p)
  select v_view, p_type, pretty_name, ''t''
  from acs_object_types
  where object_type = p_type;

  v_sort_order := 1;

  for v_type_rec in select ot2.object_type, ot2.table_name, ot2.id_column,
                    tree_level(ot2.tree_sortkey) as level
                  from acs_object_types ot1, acs_object_types ot2
                  where ot1.object_type = p_type
                    and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
                  order by ot2.tree_sortkey desc
  loop

    for v_attr_rec in select a.attribute_name, d.column_output_function, a.attribute_id,
                        a.pretty_name
                      from acs_attributes a, acs_datatypes d
                      where a.object_type = v_type_rec.object_type
                        and a.storage = ''type_specific''
                        and a.table_name is null
                        and a.datatype = d.datatype
    loop

      v_view_attribute := v_attr_rec.attribute_name;
      v_col_expr := v_type_rec.table_name || ''.'' || v_view_attribute;

      if v_attr_rec.column_output_function is not null then
        execute ''select '' || v_attr_rec.column_output_function || ''('''''' || v_col_expr ||
                '''''')'' into v_col_expr;
      end if;

      -- The check for dupes could be rolled into the select above but it is far more
      -- readable when broken out, I think.

      v_dupes := count(*)
                 from acs_attributes
                 where attribute_name = v_attr_rec.attribute_name
                   and object_type in (select ot2.object_type
                                       from acs_object_types ot1, acs_object_types ot2
                                       where ot1.object_type = v_type_rec.object_type
                                         and ot1.tree_sortkey
                                           between tree_left(ot2.tree_sortkey)
                                           and tree_right(ot2.tree_sortkey));
       if v_dupes > 0 then
         v_view_attribute := v_view_attribute || ''_'' || substr(to_char(v_dupes, ''9''),2,1);
       end if;

       insert into acs_view_attributes
         (attribute_id, view_attribute, object_view, pretty_name, sort_order, col_expr)
       values
         (v_attr_rec.attribute_id, v_view_attribute, v_view, v_attr_rec.pretty_name, v_sort_order,
          v_col_expr);

       v_sort_order := v_sort_order + 1;

    end loop;
  end loop;

  perform acs_view__create_sql_view(replace(p_type, '':'', ''_'') || ''_v'');

  -- Now fix all subtypes (really only necessary for the attributes view when an attribute
  -- has been added or dropped, but there is no harm in doing it always).  The supertype
  -- not equal to object_type bit is again due to the fact that acs_object has itself
  -- as its supertype rather than null.

  for v_type_rec in select object_type
                    from acs_object_types
                    where supertype = p_type
                      and supertype <> object_type
  loop
    perform acs_object_type__refresh_view(v_type_rec.object_type);
  end loop;

  return 0; 
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
        v_column_spec := v_column_spec || v_constraint_stub || ''_ck check('' ||
          p_attribute_name || v_datatype.check_expr || '')'';
      end if;

      if not p_null_p then
        v_column_spec := v_column_spec || v_constraint_stub || ''_nn not null'';
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

select acs_object_type__refresh_view('acs_object');
