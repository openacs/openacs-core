-- Makes the delete proc also delete grantee acs_permission records to avoid integrity violations

create or replace function acs_object__delete (integer)
returns integer as '
declare
  delete__object_id              alias for $1;  
  obj_type                       record;
begin
  
  -- Delete dynamic/generic attributes
  delete from acs_attribute_values where object_id = delete__object_id;

  -- Delete direct permissions records.
  delete from acs_permissions 
  where object_id = delete__object_id
    or  grantee_id = delete__object_id;

  -- select table_name, id_column
  --  from acs_object_types
  --  start with object_type = (select object_type
  --                              from acs_objects o
  --                             where o.object_id = delete__object_id)
  --  connect by object_type = prior supertype

  -- There was a gratuitous join against the objects table here,
  -- probably a leftover from when this was a join, and not a subquery.
  -- Functionally, this was working, but time taken was O(n) where n is the 
  -- number of objects. OUCH. Fixed. (ben)
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
      execute ''delete from '' || obj_type.table_name ||
          '' where '' || obj_type.id_column || '' =  '' || delete__object_id;
    end if;
  end loop;

  return 0; 
end;' language 'plpgsql';
