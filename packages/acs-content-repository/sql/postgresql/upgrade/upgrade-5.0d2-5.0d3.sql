-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2003-12-03
-- @cvs-id $Id: 

create or replace function content_item__get_path (integer,integer)
returns varchar as '
declare
  get_path__item_id                alias for $1;  
  get_path__root_folder_id         alias for $2;  -- default null  
  v_count                          integer;       
  v_resolved_root_id               integer;       
  v_path                           text    default '''';  
  v_rec                            record;
begin

  -- check that the item exists
  select count(*) into v_count from cr_items where item_id = get_path__item_id;

  if v_count = 0 then
    raise EXCEPTION ''-20000: Invalid item ID: %'', get_path__item_id;
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
            v_path := v_path || ''../'';
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
            v_path := v_path || ''/'';
        end if;
    end loop;

  else

    -- this is an absolute path so prepend a ''/''
    -- loop over the absolute path

    for v_rec in select i2.name, tree_level(i2.tree_sortkey) as tree_level
                 from cr_items i1, cr_items i2
                 where i2.parent_id <> 0
                 and i1.item_id = get_path__item_id
                 and i1.tree_sortkey between i2.tree_sortkey and tree_right(i2.tree_sortkey)
                 order by tree_level
    LOOP
      v_path := v_path || ''/'' || v_rec.name;
    end loop;

  end if;

  return v_path;
 
end;' language 'plpgsql';

--
-- fix setting of context_id to new item id

create or replace function content_revision__copy (integer,integer,integer,integer,varchar)
returns integer as '
declare
  copy__revision_id            alias for $1;  
  copy__copy_id                alias for $2;  -- default null  
  copy__target_item_id         alias for $3;  -- default null
  copy__creation_user          alias for $4;  -- default null
  copy__creation_ip            alias for $5;  -- default null
  v_copy_id                    cr_revisions.revision_id%TYPE;
  v_target_item_id             cr_items.item_id%TYPE;
  type_rec                     record;
begin
  -- use the specified item_id or the item_id of the original revision 
  --   if none is specified
  if copy__target_item_id is null then
    select item_id into v_target_item_id from cr_revisions 
      where revision_id = copy__revision_id;
  else
    v_target_item_id := copy__target_item_id;
  end if;

  -- use the copy_id or generate a new copy_id if none is specified
  --   the copy_id is a revision_id
  if copy__copy_id is null then
    select acs_object_id_seq.nextval into v_copy_id from dual;
  else
    v_copy_id := copy__copy_id;
  end if;

  -- create the basic object
  insert into acs_objects 
       select 
         v_copy_id as object_id, 
         object_type, 
         v_target_item_id, 
         security_inherit_p, 
         copy__creation_user as creation_user, 
         now() as creation_date, 
         copy__creation_ip as creation_ip,
         now() as last_modified, 
         copy__creation_user as modifying_user, 
         copy__creation_ip as modifying_ip 
       from
         acs_objects 
       where 
         object_id = copy__revision_id;
  
  -- create the basic revision (using v_target_item_id)
  insert into cr_revisions 
      select 
        v_copy_id as revision_id, 
        v_target_item_id as item_id, 
        title, 
        description, 
        publish_date, 
        mime_type, 
        nls_language, 
        lob,
	content,
        content_length
      from 
        cr_revisions 
      where
        revision_id = copy__revision_id;

--                  select 
--                    object_type
--                  from                                                
--                    acs_object_types                                  
--                  where                                               
--                    object_type <> ''acs_object''                       
--                  and                                                 
--                    object_type <> ''content_revision''                 
--                  connect by                                          
--                    prior supertype = object_type                     
--                  start with                                          
----                    object_type = (select object_type 
--                                     from acs_objects 
--                                    where object_id = copy__revision_id)
--                  order by
--                    level desc 

  -- iterate over the ancestor types and copy attributes
  for type_rec in select ot2.object_type, tree_level(ot2.tree_sortkey) as level
                  from acs_object_types ot1, acs_object_types ot2, acs_objects o
                  where ot2.object_type <> ''acs_object''                       
                    and ot2.object_type <> ''content_revision''
                    and o.object_id = copy__revision_id 
                    and ot1.object_type = o.object_type 
                    and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
                  order by level desc
  LOOP
    PERFORM content_revision__copy_attributes(type_rec.object_type, 
                                              copy__revision_id, v_copy_id);
  end loop;

  return v_copy_id;
 
end;' language 'plpgsql';
