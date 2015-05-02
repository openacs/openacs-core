--
-- procedure acs_object__delete/1
--
CREATE OR REPLACE FUNCTION acs_object__delete(
   delete__object_id integer
) RETURNS integer AS $$
DECLARE
  obj_type record;
BEGIN
  
  -- GN: the following deletion operation iterates over the id_columns
  -- of the acs_object_types of the type tree for the obejct and
  -- performs manual deletions in these tables by trying to delete the
  -- delete__object_id from the id_column.  This deletion includes as
  -- well the deletion in acs_objects.
  --
  -- In the best of all possible worlds, this would not
  -- be necessary, when the objects would have specified "on delete
  -- cascade" for the id_columns.

  for obj_type
  in select o2.table_name, o2.id_column
       from acs_object_types o1, acs_object_types o2
       where o1.object_type = (select object_type
                               from acs_objects o
                               where o.object_id = delete__object_id)
         and o1.tree_sortkey between o2.tree_sortkey and tree_right(o2.tree_sortkey)
    order by o2.tree_sortkey desc
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

