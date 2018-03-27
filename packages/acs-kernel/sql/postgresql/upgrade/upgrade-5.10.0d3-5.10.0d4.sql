
begin;

-- apisano 2018-02-21:
-- - added proper removal of acs_rels when deleting an acs object
-- - remove dead acs_object coming from erased portraits. Not clear
--   whether other kinds of dead objects due to other kind of
--   relationships will still be around...

-- Cleanup

-- This is not done if not uncommented, as could take a long time on busy sites!
   -- select acs_object__delete(object_id)
   --   from acs_objects o
   --   where object_type = 'user_portrait_rel'
   --     and not exists (
   --      select 1 from acs_rels
   --      where rel_id = o.object_id);

-- Data model upgrade

--
-- procedure acs_object__delete/1
--
CREATE OR REPLACE FUNCTION acs_object__delete(
   delete__object_id integer
) RETURNS integer AS $$
DECLARE
  obj_type record;
BEGIN

   -- Also child relationships must be deleted. On delete cascade
   -- would not help here, as only tuple in acs_rels would go, while
   -- related acs_object would stay.
   PERFORM acs_object__delete(object_id)
     from acs_objects where object_id in
     (select rel_id from acs_rels where
          object_id_one = delete__object_id or
          object_id_two = delete__object_id);

  -- GN: the following deletion operation iterates over the id_columns
  -- of the acs_object_types of the type tree for the object and
  -- performs manual deletions in these tables by trying to delete the
  -- delete__object_id from the id_column.  This deletion includes as
  -- well the deletion in acs_objects.
  --
  -- In the best of all possible worlds, this would not
  -- be necessary, when the objects would have specified "on delete
  -- cascade" for the id_columns.

  for obj_type
  in select ot2.table_name, ot2.id_column
       from acs_object_types ot1, acs_object_types ot2
       where ot1.object_type = (select object_type
                               from acs_objects o
                               where o.object_id = delete__object_id)
         and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
    order by ot2.tree_sortkey desc
  loop
    -- Delete from the table.

    -- DRB: I removed the quote_ident calls that DanW originally included
    -- because the table names appear to be stored in upper case.  Quoting
    -- causes them to not match the actual lower or potentially mixed-case
    -- table names.  We will just forbid squirrely names that include quotes.
    
    -- daveB
    -- ETP is creating a new object, but not a table, although it does specify a
    -- table name, so we need to check if the table exists. Wp-slim does this too

    if table_exists(obj_type.table_name) then
      execute 'delete from ' || obj_type.table_name ||
          ' where ' || obj_type.id_column || ' =  ' || delete__object_id;
    end if;
  end loop;

  return 0; 
END;
$$ LANGUAGE plpgsql;

end;
