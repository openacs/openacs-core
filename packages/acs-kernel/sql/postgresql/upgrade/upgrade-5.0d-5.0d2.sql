-- 
-- Upgrade script from 5.0d to 5.0d2
--
-- @author Simon Carstensen (simon@collaboraid.biz)
--
-- @cvs-id $Id$
--

-- Adds column timezone to table user_preferences

alter table user_preferences add column timezone varchar(100);

-- Don Baccus new update trigger that's much much faster than the old
-- one.

drop trigger acs_objects_context_id_up_tr on acs_objects;
drop function acs_objects_context_id_up_tr ();

create function acs_objects_context_id_up_tr () returns opaque as '
declare
        pair    record;
        outer record;
        inner record;
        security_context_root integer;
begin
  if new.object_id = old.object_id and
     new.context_id = old.context_id and
     new.security_inherit_p = old.security_inherit_p then
    return new;
  end if;

  -- Remove my old ancestors from my descendants.
  for outer in select object_id from acs_object_context_index where 
               ancestor_id = old.object_id and object_id <> old.object_id loop
    for inner in select ancestor_id from acs_object_context_index where
                 object_id = old.object_id and ancestor_id <> old.object_id loop
      delete from acs_object_context_index
      where object_id = outer.object_id
        and ancestor_id = inner.ancestor_id;
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

create trigger acs_objects_context_id_up_tr after update on acs_objects
for each row execute procedure acs_objects_context_id_up_tr ();
