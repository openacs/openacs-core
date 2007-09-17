-- from acs-metadata-create.sql

create or replace function acs_attribute__create_attribute (varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,integer,integer,integer,varchar,boolean)
returns integer as '
declare
  create_attribute__object_type            alias for $1;  
  create_attribute__attribute_name         alias for $2;  
  create_attribute__datatype               alias for $3;  
  create_attribute__pretty_name            alias for $4;  
  create_attribute__pretty_plural          alias for $5;  -- default null
  create_attribute__table_name             alias for $6;  -- default null
  create_attribute__column_name            alias for $7;  -- default null
  create_attribute__default_value          alias for $8;  -- default null
  create_attribute__min_n_values           alias for $9;  -- default 1
  create_attribute__max_n_values           alias for $10; -- default 1
  create_attribute__sort_order             alias for $11; -- default null
  create_attribute__storage                alias for $12; -- default ''type_specific''
  create_attribute__static_p               alias for $13; -- default ''f''

  v_sort_order           acs_attributes.sort_order%TYPE;
  v_attribute_id         acs_attributes.attribute_id%TYPE;
begin
    if create_attribute__sort_order is null then
      select coalesce(max(sort_order), 1) into v_sort_order
      from acs_attributes
      where object_type = create_attribute__object_type
      and attribute_name = create_attribute__attribute_name;
    else
      v_sort_order := create_attribute__sort_order;
    end if;

    select nextval(''t_acs_attribute_id_seq'') into v_attribute_id;

    insert into acs_attributes
      (attribute_id, object_type, table_name, column_name, attribute_name,
       pretty_name, pretty_plural, sort_order, datatype, default_value,
       min_n_values, max_n_values, storage, static_p)
    values
      (v_attribute_id, create_attribute__object_type, 
       create_attribute__table_name, create_attribute__column_name, 
       create_attribute__attribute_name, create_attribute__pretty_name,
       create_attribute__pretty_plural, v_sort_order, 
       create_attribute__datatype, create_attribute__default_value,
       create_attribute__min_n_values, create_attribute__max_n_values, 
       create_attribute__storage, create_attribute__static_p);

    return v_attribute_id;
   
end;' language 'plpgsql';

-- from acs-objects-create.sql

create or replace function acs_object__new (integer,varchar,timestamptz,integer,varchar,integer,boolean,varchar,integer)
returns integer as '
declare
  new__object_id              alias for $1;  -- default null
  new__object_type            alias for $2;  -- default ''acs_object''
  new__creation_date          alias for $3;  -- default now()
  new__creation_user          alias for $4;  -- default null
  new__creation_ip            alias for $5;  -- default null
  new__context_id             alias for $6;  -- default null
  new__security_inherit_p     alias for $7;  -- default ''t''
  new__title                  alias for $8;  -- default null
  new__package_id             alias for $9;  -- default null
  v_object_id                 acs_objects.object_id%TYPE;
  v_creation_date	      timestamptz;
  v_title                     acs_objects.title%TYPE;
  v_object_type_pretty_name   acs_object_types.pretty_name%TYPE;
begin
  if new__object_id is null then
    select nextval(''t_acs_object_id_seq'') into v_object_id;
  else
    v_object_id := new__object_id;
  end if;

  if new__title is null then
   select pretty_name
   into v_object_type_pretty_name
   from acs_object_types
   where object_type = new__object_type;

    v_title := v_object_type_pretty_name || '' '' || v_object_id;
  else
    v_title := new__title;
  end if;

  if new__creation_date is null then
   v_creation_date:= now();
  else
   v_creation_date := new__creation_date;
  end if;

  insert into acs_objects
   (object_id, object_type, title, package_id, context_id,
    creation_date, creation_user, creation_ip, security_inherit_p)
  values
   (v_object_id, new__object_type, v_title, new__package_id, new__context_id,
    v_creation_date, new__creation_user, new__creation_ip, 
    new__security_inherit_p);

  PERFORM acs_object__initialize_attributes(v_object_id);

  return v_object_id;
  
end;' language 'plpgsql';
