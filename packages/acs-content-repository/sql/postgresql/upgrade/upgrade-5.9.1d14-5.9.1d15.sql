--
-- Change text enumeration field "storage_type" in cr_items to native
-- SQL enumeration type (enumeration types are supported by PostgreSQL
-- since 8.3).
--
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'cr_item_storage_type_enum') THEN
        CREATE TYPE cr_item_storage_type_enum AS ENUM ('text', 'file', 'lob');
    END IF;

END$$;

--
-- The view "xowiki_page_live_revision" is auto-recreated on the next
-- startup of xowiki.
-- 
DROP VIEW IF EXISTS xowiki_page_live_revision;

ALTER TABLE cr_items
      DROP constraint IF EXISTS cr_items_storage_type_ck,
      ALTER COLUMN storage_type DROP DEFAULT,
      ALTER COLUMN storage_type TYPE cr_item_storage_type_enum
      USING storage_type::cr_item_storage_type_enum,
      ALTER COLUMN storage_type SET DEFAULT 'text';


--
-- We have to drop the functions with "new__storage_type character
-- varying", otherwise "create create or replace" adds additional
-- definitions.
--
-- content_item__new/17
DROP FUNCTION IF EXISTS content_item__new(new__item_id integer, new__name character varying, new__parent_id integer, new__title character varying, new__creation_date timestamp with time zone, new__creation_user integer, new__context_id integer, new__creation_ip character varying, new__is_live boolean, new__mime_type character varying, new__text text, new__storage_type character varying, new__security_inherit_p boolean, new__storage_area_key character varying, new__item_subtype character varying, new__content_type character varying, new__package_id integer );

-- content_item__new/17
DROP FUNCTION IF EXISTS content_item__new(new__item_id integer, new__name character varying, new__parent_id integer, new__title character varying, new__creation_date timestamp with time zone, new__creation_user integer, new__context_id integer, new__creation_ip character varying, new__is_live boolean, new__mime_type character varying, new__text text, new__storage_type cr_item_storage_type_enum, new__security_inherit_p boolean, new__storage_area_key character varying, new__item_subtype character varying, new__content_type character varying, new__package_id integer);

-- content_item__new/21
DROP FUNCTION IF EXISTS content_item__new(new__name character varying, new__parent_id integer, new__item_id integer, new__locale character varying, new__creation_date timestamp with time zone, new__creation_user integer, new__context_id integer, new__creation_ip character varying, new__item_subtype character varying, new__content_type character varying, new__title character varying, new__description text, new__mime_type character varying, new__nls_language character varying, new__text character varying, new__data text, new__relation_tag character varying, new__is_live boolean, new__storage_type character varying, new__package_id integer, new__with_child_rels boolean);

--
-- Replace the functions having "storage_type" as arguments.
--

--
-- procedure content_item__new/21 (accepts 19-21 args)
--
CREATE OR REPLACE FUNCTION content_item__new(
   new__name cr_items.name%TYPE,
   new__parent_id cr_items.parent_id%TYPE,              -- default null
   new__item_id acs_objects.object_id%TYPE,             -- default null
   new__locale cr_items.locale%TYPE,                    -- default null
   new__creation_date acs_objects.creation_date%TYPE,   -- default now -- default 'now'
   new__creation_user acs_objects.creation_user%TYPE,   -- default null
   new__context_id acs_objects.context_id%TYPE,         -- default null
   new__creation_ip acs_objects.creation_ip%TYPE,       -- default null
   new__item_subtype acs_object_types.object_type%TYPE, -- default 'content_item'
   new__content_type acs_object_types.object_type%TYPE, -- default 'content_revision'
   new__title cr_revisions.title%TYPE,                  -- default null
   new__description cr_revisions.description%TYPE,      -- default null
   new__mime_type cr_revisions.mime_type%TYPE,          -- default 'text/plain'
   new__nls_language cr_revisions.nls_language%TYPE,    -- default null
   new__text varchar,                                   -- default null
   new__data cr_revisions.content%TYPE,                 -- default null
   new__relation_tag cr_child_rels.relation_tag%TYPE,   -- default null
   new__is_live boolean,                                -- default 'f'
   new__storage_type cr_items.storage_type%TYPE,        -- default null
   new__package_id acs_objects.package_id%TYPE default null,
   new__with_child_rels boolean DEFAULT 't'

) RETURNS integer AS $$
DECLARE
  v_parent_id      cr_items.parent_id%TYPE;
  v_parent_type    acs_objects.object_type%TYPE;
  v_item_id        cr_items.item_id%TYPE;
  v_title          cr_revisions.title%TYPE;
  v_revision_id    cr_revisions.revision_id%TYPE;
  v_rel_id         acs_objects.object_id%TYPE;
  v_rel_tag        cr_child_rels.relation_tag%TYPE;
  v_context_id     acs_objects.context_id%TYPE;
  v_storage_type   cr_items.storage_type%TYPE;
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

     if new__relation_tag is null then
       v_rel_tag := content_item__get_content_type(v_parent_id) 
         || '-' || new__content_type;
     else
       v_rel_tag := new__relation_tag;
     end if;

     select object_type into v_parent_type from acs_objects
       where object_id = v_parent_id;

     if NOT FOUND then 
       raise EXCEPTION '-20000: Invalid parent ID % specified in content_item.new',  v_parent_id;
     end if;

     if content_item__is_subclass(v_parent_type, 'content_item') = 't' and
        content_item__is_valid_child(v_parent_id, new__content_type, v_rel_tag) = 'f' then

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
    v_item_id, new__name, new__content_type, v_parent_id, new__storage_type
  );

  -- if the parent is not a folder, insert into cr_child_rels
  if new__with_child_rels = 't' and
    v_parent_id != -4 and
    content_folder__is_folder(v_parent_id) = 'f' then

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

  if new__data is not null then
  
    -- call content_revision__new/13
    
    v_revision_id := content_revision__new(
        v_title,
	new__description,
        now(),              -- publish_date
	new__mime_type,
	new__nls_language,
	new__data,
        v_item_id,
        null,               -- revision_id
        new__creation_date, 
        new__creation_user, 
        new__creation_ip,
	null,               -- content_length
        new__package_id
        );

  elsif new__text is not null or new__title is not null then

    -- call content_revision__new/13

    v_revision_id := content_revision__new(
        v_title,
	new__description,
        now(),              -- publish_date
	new__mime_type,
        new__nls_language,
	new__text,
	v_item_id,
        null,               -- revision_id
        new__creation_date, 
        new__creation_user, 
        new__creation_ip,
	null,               -- content_length
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

--
-- procedure content_item__new/17 (accepts 16-17 args)
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
   new__text varchar,              -- default null
   new__storage_type cr_items.storage_type%TYPE,
   new__package_id integer default null

) RETURNS integer AS $$
--
-- content_item__new/17 is deprecated, one should call /20
--
DECLARE
BEGIN
	raise NOTICE 'content_item__new/17 is deprecated, call content_item__new/21 instead';

        return content_item__new(new__name,
                                 new__parent_id,
                                 new__item_id,
                                 new__locale,
                                 new__creation_date,
                                 new__creation_user,
				 new__context_id,
                                 new__creation_ip,
                                 new__item_subtype,
                                 new__content_type,
                                 new__title,
                                 new__description,
                                 new__mime_type,
                                 new__nls_language,
                                 new__text,
                                 null,  -- data
				 null,  -- relation_tag
				 'f',   -- is_live
				 new__storage_type,
                                 new__package_id,
				 't'    -- with_child_rels
               );
END;
$$ LANGUAGE plpgsql;


-- function new -- sets security_inherit_p to FALSE -DaveB
--
-- procedure content_item__new/17 (accepts 16-17 args)
--
CREATE OR REPLACE FUNCTION content_item__new(
   new__item_id integer,            --default null
   new__name varchar,
   new__parent_id integer,          -- default null
   new__title varchar,              -- default null
   new__creation_date timestamptz,  -- default now()
   new__creation_user integer,      -- default null
   new__context_id integer,         -- default null
   new__creation_ip varchar,        -- default null
   new__is_live boolean,            -- default 'f'
   new__mime_type varchar,
   new__text text,                  -- default null
   new__storage_type cr_items.storage_type%TYPE,
   new__security_inherit_p boolean, -- default 't'
   new__storage_area_key varchar,   -- default 'CR_FILES'
   new__item_subtype varchar,
   new__content_type varchar,
   new__package_id integer default null
) RETURNS integer AS $$
--
-- differs from other content_item__new/17 by
--    this version has 1st arg item_id vs. 3rd arg (differs as well from /20)
--    this version does not have a "locale" and "nls_language"
--    this version has "is_live" (like /20)
--    this version has "security_inherit_p"

DECLARE
  new__description	      varchar default null;
  new__relation_tag           varchar default null;
  new__nls_language	      varchar default null; 
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
      new__security_inherit_p,
      v_title,
      new__package_id
  );

  insert into cr_items (
    item_id, name, content_type, parent_id, storage_type, storage_area_key
  ) values (
    v_item_id, new__name, new__content_type, v_parent_id, new__storage_type,
    new__storage_area_key
  );

  -- if the parent is not a folder, insert into cr_child_rels
  if v_parent_id != -4 and
    content_folder__is_folder(v_parent_id) = 'f' and 
    content_item__is_valid_child(v_parent_id, new__content_type) = 't' then

    if new__relation_tag is null then
      v_rel_tag := content_item__get_content_type(v_parent_id) 
        || '-' || new__content_type;
    else
      v_rel_tag := new__relation_tag;
    end if;

    v_rel_id := acs_object__new(
      null,
      'cr_item_child_rel',
      new__creation_date,
      null,
      null,
      v_parent_id,
      'f',
      v_rel_tag || ': ' || v_parent_id || ' - ' || v_item_id,
      new__package_id
    );

    insert into cr_child_rels (
      rel_id, parent_id, child_id, relation_tag, order_n
    ) values (
      v_rel_id, v_parent_id, v_item_id, v_rel_tag, v_item_id
    );

  end if;

  if new__title is not null or 
     new__text is not null then

    -- call content_revision__new/13

    v_revision_id := content_revision__new(
	v_title,
	new__description,
        now(),               -- publish_date
	new__mime_type,
        null,                -- nls_language,
	new__text,
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

--
-- procedure content_item__copy/5 (accepts 3-5 args)
--
CREATE OR REPLACE FUNCTION content_item__copy(
   copy__item_id integer,
   copy__target_folder_id integer,
   copy__creation_user integer,
   copy__creation_ip varchar default null,
   copy__name varchar default null

) RETURNS integer AS $$
DECLARE
  v_current_folder_id           cr_folders.folder_id%TYPE;
  v_num_revisions               integer;       
  v_name                        cr_items.name%TYPE;
  v_content_type                cr_items.content_type%TYPE;
  v_locale                      cr_items.locale%TYPE;
  v_item_id                     cr_items.item_id%TYPE;
  v_revision_id                 cr_revisions.revision_id%TYPE;
  v_is_registered               boolean;
  v_old_revision_id             cr_revisions.revision_id%TYPE;
  v_new_revision_id             cr_revisions.revision_id%TYPE;
  v_old_live_revision_id        cr_revisions.revision_id%TYPE;
  v_new_live_revision_id        cr_revisions.revision_id%TYPE;
  v_storage_type                cr_items.storage_type%TYPE;
BEGIN

  -- call content_folder.copy if the item is a folder
  if content_folder__is_folder(copy__item_id) = 't' then
    PERFORM content_folder__copy(
        copy__item_id,
        copy__target_folder_id,
        copy__creation_user,
        copy__creation_ip,
	copy__name
    ); 

  -- call content_symlink.copy if the item is a symlink
  else if content_symlink__is_symlink(copy__item_id) = 't' then
    PERFORM content_symlink__copy(
        copy__item_id,
        copy__target_folder_id,
        copy__creation_user,
        copy__creation_ip,
	copy__name
    );

  -- call content_extlink.copy if the item is an url
  else if content_extlink__is_extlink(copy__item_id) = 't' then
    PERFORM content_extlink__copy(
        copy__item_id,
        copy__target_folder_id,
        copy__creation_user,
        copy__creation_ip,
	copy__name
    );

  -- make sure the target folder is really a folder
  else if content_folder__is_folder(copy__target_folder_id) = 't' then

    select
      parent_id
    into
      v_current_folder_id
    from
      cr_items
    where
      item_id = copy__item_id;

    select
      content_type, name, locale,
      coalesce(live_revision, latest_revision), storage_type
    into
      v_content_type, v_name, v_locale, v_revision_id, v_storage_type
    from
      cr_items
    where
      item_id = copy__item_id;

    -- copy to a different folder, or allow copy to the same folder
    -- with a different name

    if copy__target_folder_id != v_current_folder_id  or ( v_name != copy__name and copy__name is not null ) then
      -- make sure the content type of the item is registered to the folder
      v_is_registered := content_folder__is_registered(
          copy__target_folder_id,
          v_content_type,
          'f'
      );

      if v_is_registered = 't' then
        --
        -- create the new content item via content_item__new/21
	--
        v_item_id := content_item__new(
            coalesce (copy__name, v_name),
            copy__target_folder_id,
            null,               -- item_id
            v_locale,
            now(),              -- creation_date
            copy__creation_user,
            null,               -- context_id
            copy__creation_ip,
            'content_item',            
            v_content_type,
            null,               -- title
            null,               -- description
            'text/plain',       -- mime_type
            null,               -- nls_language
            null,               -- text
            null,               -- data
            null,               -- relation_tag
            'f',                -- is_live	    
            v_storage_type,
	    null,               -- package_id
	    't'                 -- with_child_rels
        );

	select
          latest_revision, live_revision into v_old_revision_id, v_old_live_revision_id
        from
       	  cr_items
        where
       	  item_id = copy__item_id;
	end if;

        -- copy the latest revision (if any) to the new item
	if v_old_revision_id is not null then
          v_new_revision_id := content_revision__copy (
              v_old_revision_id,
              null,
              v_item_id,
              copy__creation_user,
              copy__creation_ip
          );
        end if;

        -- copy the live revision (if there is one and it differs from the latest) to the new item
	if v_old_live_revision_id is not null then
          if v_old_live_revision_id <> v_old_revision_id then
            v_new_live_revision_id := content_revision__copy (
              v_old_live_revision_id,
              null,
              v_item_id,
              copy__creation_user,
              copy__creation_ip
            );
          else
            v_new_live_revision_id := v_new_revision_id;
          end if;
        end if;

        update cr_items set live_revision = v_new_live_revision_id, latest_revision = v_new_revision_id where item_id = v_item_id;

    end if;

  end if; end if; end if; end if;

  return v_item_id;

END;
$$ LANGUAGE plpgsql;

