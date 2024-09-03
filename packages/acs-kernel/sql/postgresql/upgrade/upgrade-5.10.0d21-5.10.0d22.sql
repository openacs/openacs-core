-- Redefine acs_object__name using dot notation so it will look
-- exactly like the Oracle version and no code divergency will be
-- needed anymore.

CREATE SCHEMA acs_object;

--
-- procedure acs_object__name/1
--
CREATE OR REPLACE FUNCTION acs_object.name(
   name__object_id integer
) RETURNS varchar AS $$
DECLARE
  object_name            varchar;
  v_object_id            integer;
  obj_type               record;
  obj                    record;
BEGIN
  -- Find the name function for this object, which is stored in the
  -- name_method column of acs_object_types. Starting with this
  -- object's actual type, traverse the type hierarchy upwards until
  -- a non-null name_method value is found.
  --
  -- select name_method
  --  from acs_object_types
  -- start with object_type = (select object_type
  --                             from acs_objects o
  --                            where o.object_id = name__object_id)
  -- connect by object_type = prior supertype

  select title into object_name
  from acs_objects
  where object_id = name__object_id;

  if (object_name is not null) then
    return object_name;
  end if;

  for obj_type
  in select ot2.name_method
        from acs_object_types ot1, acs_object_types ot2
       where ot1.object_type = (select object_type
                                 from acs_objects o
                                where o.object_id = name__object_id)
         and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
    order by ot2.tree_sortkey desc
  loop
   if obj_type.name_method != '' and obj_type.name_method is NOT null then

    -- Execute the first name_method we find (since we're traversing
    -- up the type hierarchy from the object's exact type) using
    -- Native Dynamic SQL, to ascertain the name of this object.
    --
    --execute 'select ' || object_type.name_method || '(:1) from dual'

    for obj in execute 'select ' || obj_type.name_method || '(' || name__object_id || ')::varchar as object_name' loop
        object_name := obj.object_name;
        exit;
    end loop;

    exit;
   end if;
  end loop;

  return object_name;

END;
$$ LANGUAGE plpgsql stable strict;

CREATE OR REPLACE FUNCTION acs_object__name(
   name__object_id integer
) RETURNS varchar AS $$
BEGIN
  RETURN acs_object.name(name__object_id);
END;
$$ LANGUAGE plpgsql stable strict;
