--
-- fix typo in variable name "new_nls_language" (must be "new__nls_language")
--
-- Same as upgrade-5.9.2d1-5.9.2d2

--
-- procedure content_item__new/17 (accepts 15-17 args)
--
CREATE OR REPLACE FUNCTION content_item__new(
   new__name varchar,
   new__parent_id integer,         -- default null
   new__item_id integer,           -- default null
   new__locale varchar,            -- default null
   new__creation_date timestamptz, -- default now()
   new__creation_user integer,     -- default null
   new__context_id integer,        -- default null
   new__creation_ip varchar,       -- default null
   new__item_subtype varchar,      -- default 'content_item'
   new__content_type varchar,      -- default 'content_revision'
   new__title varchar,             -- default null
   new__description varchar,       -- default null
   new__mime_type varchar,         -- default 'text/plain'
   new__nls_language varchar,      -- default null
   new__data integer,              -- default null
   new__package_id integer default null,
   new__with_child_rels boolean DEFAULT 't'

) RETURNS integer AS $$
--
-- This version passes "data" as integer (lob version), most other use
-- "text" and "storage_type"
-- 
DECLARE
  new__relation_tag           varchar default null;
  new__is_live                boolean default 'f';

  v_parent_id                 cr_items.parent_id%TYPE;
  v_parent_type               acs_objects.object_type%TYPE;
  v_item_id                   cr_items.item_id%TYPE;
  v_revision_id               cr_revisions.revision_id%TYPE;
  v_title                     cr_revisions.title%TYPE;
  v_rel_id                    acs_objects.object_id%TYPE;
  v_rel_tag                   cr_child_rels.relation_tag%TYPE;
  v_context_id                acs_objects.context_id%TYPE;
BEGIN

  -- place the item in the context of the pages folder if no
  -- context specified 

  if new__parent_id is null then
    select c_root_folder_id from content_item_globals into v_parent_id;
  else
    v_parent_id := new__parent_id;
  end if;

  -- Determine context_id
  if new__context_id is null then
    v_context_id := v_parent_id;
  else
    v_context_id := new__context_id;
  end if;

  -- use the name of the item if no title is supplied
  if new__title is null or new__title = '' then
    v_title := new__name;
  else
    v_title := new__title;
  end if;

  if v_parent_id = -4 or 
    content_folder__is_folder(v_parent_id) = 't' then

    if v_parent_id != -4 and 
      content_folder__is_registered(
        v_parent_id, new__content_type, 'f') = 'f' then

      raise EXCEPTION '-20000: This items content type % is not registered to this folder %', new__content_type, v_parent_id;
    end if;

  else if v_parent_id != -4 then

     select object_type into v_parent_type from acs_objects
       where object_id = v_parent_id;

     if NOT FOUND then 
       raise EXCEPTION '-20000: Invalid parent ID % specified in content_item.new',  v_parent_id;
     end if;

     if content_item__is_subclass(v_parent_type, 'content_item') = 't' and
	content_item__is_valid_child(v_parent_id, new__content_type) = 'f' then

       raise EXCEPTION '-20000: This items content type % is not allowed in this container %', new__content_type, v_parent_id;
     end if;

  end if; end if;

  -- Create the object

  v_item_id := acs_object__new(
      new__item_id,
      new__item_subtype, 
      new__creation_date, 
      new__creation_user, 
      new__creation_ip, 
      v_context_id,
      't',
      v_title,
      new__package_id
  );

  insert into cr_items (
    item_id, name, content_type, parent_id, storage_type
  ) values (
    v_item_id, new__name, new__content_type, v_parent_id, 'lob'
  );

  -- if the parent is not a folder, insert into cr_child_rels
  if new__with_child_rels = 't' and
    v_parent_id != -4 and
    content_folder__is_folder(v_parent_id) = 'f' and
    content_item__is_valid_child(v_parent_id, new__content_type) = 't' then

    if new__relation_tag is null or new__relation_tag = '' then
      v_rel_tag := content_item__get_content_type(v_parent_id) 
        || '-' || new__content_type;
    else
      v_rel_tag := new__relation_tag;
    end if;

    v_rel_id := acs_object__new(
      null,
      'cr_item_child_rel',
      now(),
      null,
      null,
      v_parent_id,
      't',
      v_rel_tag || ': ' || v_parent_id || ' - ' || v_item_id,
      new__package_id
    );

    insert into cr_child_rels (
      rel_id, parent_id, child_id, relation_tag, order_n
    ) values (
      v_rel_id, v_parent_id, v_item_id, v_rel_tag, v_item_id
    );

  end if;

  -- create the revision if data or title is not null

  if new__data is not null then

    -- call content_revision__new/12 (data is integer)
    
    v_revision_id := content_revision__new(
        v_title,
	new__description,
        now(),               -- publish_date
	new__mime_type,
	new__nls_language,
	new__data,
        v_item_id,
        null,                -- revision_id
        new__creation_date, 
        new__creation_user, 
        new__creation_ip,
        new__package_id
        );

  elsif new__title is not null then

    -- call content_revision__new/13 (data is null)

    v_revision_id := content_revision__new(
	v_title,
	new__description,
        now(),               -- publish_date
	new__mime_type,
        new__nls_language,
	null,                -- data/text
	v_item_id,
        null,                -- revision_id
        new__creation_date, 
        new__creation_user, 
        new__creation_ip,
	null,                -- content_length
        new__package_id
    );

  end if;

  -- make the revision live if is_live is true
  if new__is_live = 't' then
    PERFORM content_item__set_live_revision(v_revision_id);
  end if;

  return v_item_id;
 
END;
$$ LANGUAGE plpgsql;
