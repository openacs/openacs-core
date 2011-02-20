
select define_function_args('content_type__create_type','content_type,supertype;content_revision,pretty_name,pretty_plural,table_name,id_column,name_method');

create or replace function content_type__create_type (varchar,varchar,varchar,varchar,varchar,varchar,varchar)
returns integer as '
declare
  create_type__content_type           alias for $1;  
  create_type__supertype              alias for $2;  -- default ''content_revision''  
  create_type__pretty_name            alias for $3;  
  create_type__pretty_plural          alias for $4;  
  create_type__table_name             alias for $5;
  create_type__id_column              alias for $6;  -- default ''XXX''
  create_type__name_method            alias for $7;  -- default null
  v_temp_p                            boolean;       
  v_supertype_table                   acs_object_types.table_name%TYPE;
                                        
begin

  if (create_type__supertype <> ''content_revision'')
      and (create_type__content_type <> ''content_revision'') then
    select count(*) > 0 into v_temp_p
    from  acs_object_type_supertype_map
    where object_type = create_type__supertype
    and ancestor_type = ''content_revision'';

    if not v_temp_p then
      raise EXCEPTION ''-20000: supertype % must be a subtype of content_revision'', create_type__supertype;
    end if;
  end if;

  select count(*) = 0 into v_temp_p 
    from pg_class
   where relname = lower(create_type__table_name);

  PERFORM acs_object_type__create_type (
    create_type__content_type,
    create_type__pretty_name,
    create_type__pretty_plural,
    create_type__supertype,
    create_type__table_name,
    create_type__id_column,
    null,
    ''f'',
    null,
    create_type__name_method,
    v_temp_p,
    ''f''
  );

  PERFORM content_type__refresh_view(create_type__content_type);

  return 0; 
end;' language 'plpgsql';

select define_function_args('content_type__create_attribute','content_type,attribute_name,datatype,pretty_name,pretty_plural,sort_order,default_value,column_spec;text');

create or replace function content_type__create_attribute (varchar,varchar,varchar,varchar,varchar,integer,varchar,varchar)
returns integer as '
declare
  create_attribute__content_type           alias for $1;  
  create_attribute__attribute_name         alias for $2;  
  create_attribute__datatype               alias for $3;  
  create_attribute__pretty_name            alias for $4;  
  create_attribute__pretty_plural          alias for $5;  -- default null  
  create_attribute__sort_order             alias for $6;  -- default null
  create_attribute__default_value          alias for $7;  -- default null
  create_attribute__column_spec            alias for $8;  -- default ''text''
  v_attr_id                                acs_attributes.attribute_id%TYPE;
  v_table_name                             acs_object_types.table_name%TYPE;
  v_column_exists                          boolean;       
begin

 -- add the appropriate column to the table
 
 select table_name into v_table_name from acs_object_types
  where object_type = create_attribute__content_type;

 if NOT FOUND then
   raise EXCEPTION ''-20000: Content type % does not exist in content_type.create_attribute'', create_attribute__content_type;
 end if; 

 select count(*) > 0 into v_column_exists 
   from pg_class c, pg_attribute a
  where c.relname::varchar = v_table_name
    and c.oid = a.attrelid
    and a.attname = lower(create_attribute__attribute_name);

 v_attr_id := acs_attribute__create_attribute (
   create_attribute__content_type,
   create_attribute__attribute_name,
   create_attribute__datatype,
   create_attribute__pretty_name,
   create_attribute__pretty_plural,
   null,
   null,
   create_attribute__default_value,
   1,
   1,
   create_attribute__sort_order,
   ''type_specific'',
   ''f'',
   not v_column_exists,
   null,
   null,
   null,
   null,
   null,
   create_attribute__column_spec
 );

 PERFORM content_type__refresh_view(create_attribute__content_type);

 return v_attr_id;

end;' language 'plpgsql';
