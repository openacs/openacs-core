
select define_function_args('acs_object_type__drop_type','object_type,drop_table_p;f,drop_children_p;f');

-- procedure drop_type
create or replace function acs_object_type__drop_type (varchar,boolean,boolean)
returns integer as '
declare
  p_object_type                     alias for $1;  
  p_drop_children_p                 alias for $2;
  p_drop_table_p                    alias for $3;
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
      perform acs_object_type__drop_type(row.object_type, ''t'', p_drop_table_p);
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
  return acs_object_type__drop_type($1,$2,''f'');
end;' language 'plpgsql';

