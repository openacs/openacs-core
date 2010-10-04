-- Support for postgresql 9.x
-- @author Victor Guerra (vguerra@gmail.com)

create or replace function acs_objects_context_id_up_tr () returns trigger as '
declare
        pair    record;
        outer_record record;
        inner_record record;
        security_context_root integer;
begin
  if new.object_id = old.object_id
     and ((new.context_id = old.context_id)
	  or (new.context_id is null and old.context_id is null))
     and new.security_inherit_p = old.security_inherit_p then
    return new;
  end if;

  -- Remove my old ancestors from my descendants.
  for outer_record in select object_id from acs_object_context_index where 
               ancestor_id = old.object_id and object_id <> old.object_id loop
    for inner_record in select ancestor_id from acs_object_context_index where
                 object_id = old.object_id and ancestor_id <> old.object_id loop
      delete from acs_object_context_index
      where object_id = outer_record.object_id
        and ancestor_id = inner_record.ancestor_id;
    end loop;
  end loop;

  -- Kill all my old ancestors.
  delete from acs_object_context_index
  where object_id = old.object_id;

  insert into acs_object_context_index
   (object_id, ancestor_id, n_generations)
  values
   (new.object_id, new.object_id, 0);

  if new.context_id is not null and new.security_inherit_p = ''t'' then
     -- Now insert my new ancestors for my descendants.
    for pair in select *
		 from acs_object_context_index
		 where ancestor_id = new.object_id 
    LOOP
      insert into acs_object_context_index
       (object_id, ancestor_id, n_generations)
      select
       pair.object_id, ancestor_id,
       n_generations + pair.n_generations + 1 as n_generations
      from acs_object_context_index
      where object_id = new.context_id;
    end loop;
  else
    security_context_root = acs__magic_object_id(''security_context_root'');
    if new.object_id != security_context_root then
    -- We need to make sure that new.OBJECT_ID and all of its
    -- children have security_context_root as an ancestor.
    for pair in  select *
		 from acs_object_context_index
		 where ancestor_id = new.object_id 
      LOOP
        insert into acs_object_context_index
         (object_id, ancestor_id, n_generations)
        values
         (pair.object_id, security_context_root, pair.n_generations + 1);
      end loop;
    end if;
  end if;

  return new;

end;' language 'plpgsql';

create or replace function acs_object__get_attribute (integer,varchar)
returns text as '
declare
  object_id_in           alias for $1;  
  attribute_name_in      alias for $2;  
  v_table_name           varchar(200);  
  v_column               varchar(200);  
  v_key_sql              text; 
  v_return               text; 
  v_storage              text;
  v_rec                  record;
begin

   v_storage := acs_object__get_attribute_storage(object_id_in, attribute_name_in);

   v_column     := acs_object__get_attr_storage_column(v_storage);
   v_table_name := acs_object__get_attr_storage_table(v_storage);
   v_key_sql    := acs_object__get_attr_storage_sql(v_storage);

   for v_rec in execute ''select '' || quote_ident(v_column) || ''::text as column_return from '' || quote_ident(v_table_name) || '' where '' || v_key_sql
      LOOP
        v_return := v_rec.column_return;
        exit;
   end loop;
   if not FOUND then 
       return null;
   end if;

   return v_return;

end;' language 'plpgsql' stable;
