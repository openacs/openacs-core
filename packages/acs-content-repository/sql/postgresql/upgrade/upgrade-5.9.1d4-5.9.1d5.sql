--
-- reduce number of versions of content_item__new from 12 to 6 by using defaults
-- commented differences
-- commented arguments of plpgsql functions with long argument lists
-- reduced code duplication by basing one version of content_item__new/17 directly on /20
-- marking on version of content_item__new/17 and content_item__new/6 as deprecated
--

-- content_item__new/19 content_item__new/20
DROP FUNCTION IF EXISTS content_item__new(character varying, integer, integer, character varying, timestamp with time zone, integer, integer, character varying, character varying, character varying, character varying, text, character varying, character varying, character varying, text, character varying, boolean, character varying, integer);
DROP FUNCTION IF EXISTS content_item__new(character varying, integer, integer, character varying, timestamp with time zone, integer, integer, character varying, character varying, character varying, character varying, text, character varying, character varying, character varying, text, character varying, boolean, character varying);

-- content_item__new/16 content_item__new/17
DROP FUNCTION IF EXISTS content_item__new(varchar, integer, integer, varchar, timestamptz, integer, integer, varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar, integer);
DROP FUNCTION IF EXISTS content_item__new(varchar, integer, integer, varchar, timestamptz, integer, integer, varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar);

-- content_item__new/15 content_item__new/16
DROP FUNCTION IF EXISTS content_item__new(varchar,integer,integer, varchar,timestamptz, integer, integer, varchar, varchar, varchar, varchar, varchar, varchar, varchar, integer, integer);
DROP FUNCTION IF EXISTS content_item__new(varchar,integer,integer, varchar,timestamptz, integer, integer, varchar, varchar, varchar, varchar, varchar, varchar, varchar, integer);

-- content_item__new/5 content_item__new/6
DROP FUNCTION IF EXISTS content_item__new(varchar, integer, varchar, text, text, integer);
DROP FUNCTION IF EXISTS content_item__new(varchar, integer, varchar, text, text);

-- content_item__new/2 content_item__new/3
DROP FUNCTION IF EXISTS content_item__new(varchar, integer, integer);
DROP FUNCTION IF EXISTS content_item__new(varchar, integer);

-- procedure content_item__new/16 content_item__new/17
DROP FUNCTION IF EXISTS content_item__new(integer, varchar, integer, varchar, timestamptz, integer, integer, varchar, boolean, varchar, text, varchar, boolean, varchar, varchar, varchar, integer);
DROP FUNCTION IF EXISTS content_item__new(integer, varchar, integer, varchar, timestamptz, integer, integer, varchar, boolean, varchar, text, varchar, boolean, varchar, varchar, varchar);



select define_function_args('content_item__new','name,parent_id;null,item_id;null,locale;null,creation_date;now,creation_user;null,context_id;null,creation_ip;null,item_subtype;content_item,content_type;content_revision,title;null,description;null,mime_type;text/plain,nls_language;null,text;null,data;null,relation_tag;null,is_live;f,storage_type;null,package_id;null');
--
-- procedure content_item__new/20 content_item__new/19
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
   new__package_id acs_objects.package_id%TYPE default null

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
  if v_parent_id != -4 and
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
	null,
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
	null,
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
-- procedure content_item__new/16 content_item__new/17
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
   new__storage_type varchar,      -- check in ('text','file')
   new__package_id integer default null

) RETURNS integer AS $$
--
-- content_item__new/17 might become obsolete, when we define proper defaults for /20
--
DECLARE
BEGIN
	raise NOTICE 'content_item__new/17 is deprecated, call content_item__new/20 instead';

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
                                 new__package_id
               );
END;
$$ LANGUAGE plpgsql;



--
-- procedure content_item__new/15 content_item__new/16
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
   new__package_id integer default null
) RETURNS integer AS $$
--
-- content_item__new/16 maybe obsolete, when we define proper defaults for /20
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
  if v_parent_id != -4 and
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
        new_nls_language,
	null,                -- data/text
	v_item_id,
        null,                -- revision_id
        new__creation_date, 
        new__creation_user, 
        new__creation_ip,
	null,
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
-- procedure content_item__new/5 content_item__new/6
--
CREATE OR REPLACE FUNCTION content_item__new(
   new__name varchar,
   new__parent_id integer, -- default null
   new__title varchar,     -- default null
   new__description text,  -- default null
   new__text text,         -- default null
   new__package_id integer default null
) RETURNS integer AS $$
DECLARE
BEGIN
	raise NOTICE 'content_item__new/6 is deprecated, call content_item__new/20 instead';

	-- calls content_item__new/20

        return content_item__new(new__name,
                                 new__parent_id,
                                 null,               -- item_id
                                 null,               -- locale
                                 now(),              -- creation_date 
                                 null,               -- creation_user
                                 null,               -- context_id
                                 null,               -- creation_ip
                                 'content_item',     -- item_subtype
                                 'content_revision', -- content_type
                                 new__title,
                                 new__description,
                                 'text/plain',       -- mime_type
                                 null,               -- nls_language
                                 new__text,
                                 null,               -- data
				 null,               -- relation_tag
				 'f',                -- is_live				 
                                 'text',             -- storage_type
                                 new__package_id
               );

END;
$$ LANGUAGE plpgsql;

--
-- procedure content_item__new/2 content_item__new/3
--
CREATE OR REPLACE FUNCTION content_item__new(
   new__name varchar,
   new__parent_id integer,
   new__package_id integer default null
) RETURNS integer AS $$
--
-- calls content_item__new/6
--
DECLARE
BEGIN
        return content_item__new(new__name, new__parent_id, null, null, null, new__package_id);
END;
$$ LANGUAGE plpgsql;



-- function new -- sets security_inherit_p to FALSE -DaveB
--
-- procedure content_item__new/16 content_item__new/17
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
   new__storage_type varchar,       -- check in ('text', 'file')
   new__security_inherit_p boolean, -- default 't'
   new__storage_area_key varchar,   -- default 'CR_FILES'
   new__item_subtype varchar,
   new__content_type varchar,
   new__package_id integer default null

) RETURNS integer AS $$
--
-- content_item__new/17 maybe obsolete, when we define proper defaults for /20
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




CREATE OR REPLACE FUNCTION content_item__new(
   new__name varchar,
   new__parent_id integer, -- default null
   new__title varchar default null,
   new__description text default null,
   new__text text default null,
   new__package_id integer default null
) RETURNS integer AS $$
--
-- content_item__new/6 maybe obsolete, when we define proper defaults for /20
--
-- calls content_item__new/17
DECLARE
BEGIN
        return content_item__new(new__name,
                                 new__parent_id,
                                 null,
                                 null,
                                 now(),
                                 null,
                                 null,
                                 null,
                                 'content_item',
                                 'content_revision',   
                                 new__title,
                                 new__description,
                                 'text/plain',
                                 null,
                                 new__text,
                                 'text',
                                 new__package_id
               );

END;
$$ LANGUAGE plpgsql;
