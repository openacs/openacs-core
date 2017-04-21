

CREATE OR REPLACE FUNCTION content_item__get_path(
   get_path__item_id integer,
   get_path__root_folder_id integer -- default null

) RETURNS varchar AS $$
DECLARE
  v_count                          integer;       
  v_resolved_root_id               integer;       
  v_path                           text    default '';  
  v_rec                            record;
  v_current_item_id                integer;
  v_current_name                   text;
BEGIN

  -- check that the item exists
  select count(*) into v_count from cr_items where item_id = get_path__item_id;

  if v_count = 0 then
    raise EXCEPTION '-20000: Invalid item ID: %', get_path__item_id;
  end if;

  -- begin walking down the path to the item (from the repository root)
 
  -- if the root folder is not null then prepare for a relative path

  if get_path__root_folder_id is not null then

    -- if root_folder_id is a symlink, resolve it (child items will point
    -- to the actual folder, not the symlink)

    v_resolved_root_id := content_symlink__resolve(get_path__root_folder_id);

    -- check to see if the item is under or out side the root_id
    PERFORM 1 from cr_items i, 
        (select tree_sortkey from cr_items where item_id = v_resolved_root_id) a
    where tree_ancestor_p(a.tree_sortkey, i.tree_sortkey) and i.item_id = get_path__item_id;

    if NOT FOUND then
        -- if not found then we need to go up the folder and append ../ until we have common ancestor

        for v_rec in select i1.name, i1.parent_id, tree_level(i1.tree_sortkey) as tree_level
                 from cr_items i1, (select tree_ancestor_keys(tree_sortkey) as tree_sortkey from cr_items where item_id = v_resolved_root_id) i2,
                 (select tree_sortkey from cr_items where item_id = get_path__item_id) i3
                 where 
                 i1.parent_id <> 0
                 and i2.tree_sortkey = i1.tree_sortkey
                 and not tree_ancestor_p(i2.tree_sortkey, i3.tree_sortkey)
                 order by tree_level desc
        LOOP
            v_path := v_path || '../';
        end loop;
        -- lets now assign the new root_id to be the last parent_id on the loop
        v_resolved_root_id := v_rec.parent_id;

    end if;

    -- go downwards the tree and append the name and /
    for v_rec in select i1.name, i1.item_id, tree_level(i1.tree_sortkey) as tree_level
             from cr_items i1, (select tree_sortkey from cr_items where item_id = v_resolved_root_id) i2,
            (select tree_ancestor_keys(tree_sortkey) as tree_sortkey from cr_items where item_id = get_path__item_id) i3
             where 
             i1.tree_sortkey = i3.tree_sortkey
             and i1.tree_sortkey > i2.tree_sortkey
             order by tree_level
    LOOP
        v_path := v_path || v_rec.name;
        if v_rec.item_id <> get_path__item_id then 
            -- put a / if we are still going down
            v_path := v_path || '/';
        end if;
    end loop;

  else

    -- this is an absolute path so prepend a '/'
    -- loop over the absolute path

    v_current_item_id := get_path__item_id;

    while v_current_item_id <> 0
    LOOP
      select parent_id, name into v_current_item_id, v_current_name from cr_items where item_id = v_current_item_id;
      if FOUND then
        v_path :=  '/' || v_current_name || v_path;
      end if;
    end loop;

  end if;

  return v_path;
 
END;
$$ LANGUAGE plpgsql;
