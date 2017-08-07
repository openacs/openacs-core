-- Data model to support content repository of the ArsDigita
-- Community System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

create or replace view content_item_globals as 
select -100 as c_root_folder_id;


--
-- procedure content_item__get_root_folder/1
--
select define_function_args('content_item__get_root_folder','item_id;null');

CREATE OR REPLACE FUNCTION content_item__get_root_folder(
   get_root_folder__item_id integer -- default null

) RETURNS integer AS $$
DECLARE
  v_folder_id                             cr_folders.folder_id%TYPE;
BEGIN

  if get_root_folder__item_id is NULL or get_root_folder__item_id in (-4,-100,-200) then

    select c_root_folder_id from content_item_globals into v_folder_id;

  else

    select i2.item_id into v_folder_id
    from cr_items i1, cr_items i2
    where i2.parent_id = -4
    and i1.item_id = get_root_folder__item_id
    and i1.tree_sortkey between i2.tree_sortkey and tree_right(i2.tree_sortkey);

    if NOT FOUND then
       raise EXCEPTION ' -20000: Could not find a root folder for item ID %. Either the item does not exist or its parent value is corrupted.', get_root_folder__item_id;
    end if;
  end if;    

  return v_folder_id;
 
END;
$$ LANGUAGE plpgsql stable;


select define_function_args('content_item__new','name,parent_id;null,item_id;null,locale;null,creation_date;now,creation_user;null,context_id;null,creation_ip;null,item_subtype;content_item,content_type;content_revision,title;null,description;null,mime_type;text/plain,nls_language;null,text;null,data;null,relation_tag;null,is_live;f,storage_type;null,package_id;null,with_child_rels;t');

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
        new_nls_language,
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



--
-- procedure content_item__new/6 (accepts 5-6 args)
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
	raise NOTICE 'content_item__new/5 is deprecated, call content_item__new/21 instead';

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
                                 new__package_id,
				 't'                 -- with_child_rels
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


select define_function_args('content_item__is_published','item_id');
--
-- procedure content_item__is_published/1
--
CREATE OR REPLACE FUNCTION content_item__is_published(
   is_published__item_id integer
) RETURNS boolean AS $$
DECLARE
BEGIN

  return
    count(*) > 0
  from
    cr_items
  where
    live_revision is not null
  and
    publish_status = 'live'
  and
    item_id = is_published__item_id;
 
END;
$$ LANGUAGE plpgsql stable;


select define_function_args('content_item__is_publishable','item_id');
--
-- procedure content_item__is_publishable/1
--
CREATE OR REPLACE FUNCTION content_item__is_publishable(
   is_publishable__item_id integer
) RETURNS boolean AS $$
DECLARE
  v_child_count                          integer;       
  v_rel_count                            integer;       
  v_content_type			 varchar;
  v_template_id                          cr_templates.template_id%TYPE;
  v_child_type                           record;
  v_rel_type                             record;
  -- v_pub_wf                               record;
BEGIN
  -- check valid item_id
  select content_item__get_content_type(is_publishable__item_id) into v_content_type;

  if v_content_type is null then 
	raise exception 'content_item__is_publishable item_id % invalid',is_publishable__item_id;
  end if;

  -- validate children
  -- make sure the # of children of each type fall between min_n and max_n
  for v_child_type in select child_type, min_n, max_n
                      from   cr_type_children
                      where  parent_type = v_content_type 
	              and    (min_n is not null or max_n is not null)
  LOOP
    select count(item_id) into v_child_count
    from   cr_items
    where  parent_id = is_publishable__item_id
    and    content_item__get_content_type(child_id) = v_child_type.child_type;

    -- make sure # of children is in range
    if v_child_type.min_n is not null 
      and v_child_count < v_child_type.min_n then
      return 'f';
    end if;
    if v_child_type.max_n is not null
      and v_child_count > v_child_type.max_n then
      return 'f';
    end if;

  end LOOP;

  -- validate relations
  -- make sure the # of ext links of each type fall between min_n and max_n
  -- only check if one of min_n max_n not null
  for v_rel_type in select target_type, min_n, max_n
                    from   cr_type_relations
                    where  content_type = v_content_type
		    and    (max_n is not null or min_n is not null)
  LOOP
    select count(rel_id) into v_rel_count
    from   cr_item_rels i, acs_objects o
    where  i.related_object_id = o.object_id
    and    i.item_id = is_publishable__item_id
    and    coalesce(content_item__get_content_type(o.object_id),o.object_type) = v_rel_type.target_type;
      
    -- make sure # of object relations is in range
    if v_rel_type.min_n is not null 
      and v_rel_count < v_rel_type.min_n then
      return 'f';
    end if;
    if v_rel_type.max_n is not null 
      and v_rel_count > v_rel_type.max_n then
      return 'f';
    end if;
  end loop;

  -- validate publishing workflows
  -- make sure any 'publishing_wf' associated with this item are finished
  -- KG: logic is wrong here.  Only the latest workflow matters, and even
  -- that is a little problematic because more than one workflow may be
  -- open on an item.  In addition, this should be moved to CMS.
  
  -- Removed this as having workflow stuff in the CR is just plain wrong.
  -- DanW, Aug 25th, 2001.

  --   for v_pub_wf in  select
  --                      case_id, state
  --                    from
  --                      wf_cases
  --                    where
  --                      workflow_key = 'publishing_wf'
  --                    and
  --                      object_id = is_publishable__item_id
  -- 
  --   LOOP
  --     if v_pub_wf.state != 'finished' then
  --        return 'f';
  --     end if;
  --   end loop;

  -- if NOT FOUND then 
  --   return 'f';
  -- end if;

  return 't';
 
END;
$$ LANGUAGE plpgsql stable;


select define_function_args('content_item__is_valid_child','item_id,content_type,relation_tag');
--
-- procedure content_item__is_valid_child/3
--
CREATE OR REPLACE FUNCTION content_item__is_valid_child(
   is_valid_child__item_id integer,
   is_valid_child__content_type varchar,
   is_valid_child__relation_tag varchar
) RETURNS boolean AS $$
DECLARE
  v_is_valid_child                       boolean;       
  v_max_children                         cr_type_children.max_n%TYPE;
  v_n_children                           integer;       
  v_null_exists				 boolean;
BEGIN

  v_is_valid_child := 'f';

  -- first check if content_type is a registered child_type
  select sum(max_n) into v_max_children
  from   cr_type_children
  where  parent_type = content_item__get_content_type(is_valid_child__item_id)
  and    child_type = is_valid_child__content_type
  and    (is_valid_child__relation_tag is null or is_valid_child__relation_tag = relation_tag);

  if NOT FOUND then 
      return 'f';
  end if;

  -- if the max is null then infinite number is allowed
  if v_max_children is null then
    return 't';
  end if;

  --
  -- Next check if there are already max_n children of that content type.
  -- Use cr_child_rels only, when a non-null relation_tag is provided.
  --
  if is_valid_child__relation_tag is null then
        select count(item_id) into v_n_children
        from   cr_items
        where  parent_id = is_valid_child__item_id
        and    content_item__get_content_type(child_id) = is_valid_child__content_type;
  else
        select count(rel_id) into v_n_children
        from   cr_child_rels
        where  parent_id = is_valid_child__item_id
        and    content_item__get_content_type(child_id) = is_valid_child__content_type
        and    is_valid_child__relation_tag = relation_tag;
  end if;
  
  if NOT FOUND then 
     return 'f';
  end if;

  if v_n_children < v_max_children then
    v_is_valid_child := 't';
  end if;

  return v_is_valid_child;
 
END;
$$ LANGUAGE plpgsql stable;




--
-- procedure content_item__is_valid_child/2
--
CREATE OR REPLACE FUNCTION content_item__is_valid_child(
   is_valid_child__item_id integer,
   is_valid_child__content_type varchar
) RETURNS boolean AS $$
--
-- variant without relation_tag
--
DECLARE
  v_is_valid_child                       boolean;       
  v_max_children                         cr_type_children.max_n%TYPE;
  v_n_children                           integer;       
BEGIN

  v_is_valid_child := 'f';

  -- first check if content_type is a registered child_type
  select sum(max_n) into v_max_children
  from   cr_type_children
  where  parent_type = content_item__get_content_type(is_valid_child__item_id)
  and    child_type = is_valid_child__content_type;

  if NOT FOUND then 
     return 'f';
  end if;

  -- if the max is null then infinite number is allowed
  if v_max_children is null then
    return 't';
  end if;

  -- next check if there are already max_n children of that content type
  select count(item_id) into v_n_children
  from   cr_items
  where  parent_id = is_valid_child__item_id
  and    content_item__get_content_type(child_id) = is_valid_child__content_type;

  if NOT FOUND then 
     return 'f';
  end if;

  if v_n_children < v_max_children then
    v_is_valid_child := 't';
  end if;

  return v_is_valid_child;
 
END;
$$ LANGUAGE plpgsql stable;


--
-- Delete a content item
--
-- Technically, the following steps are necessary, some of these are
-- achieved via cascading operations:
--
-- 1) delete all associated workflows
-- 2) delete all symlinks associated with this object
-- 3) delete any revisions for this item
-- 4) unregister template relations
-- 5) delete all permissions associated with this item
-- 6) delete keyword associations
-- 7) delete all associated comments

select define_function_args('content_item__del','item_id');

--
-- procedure content_item__del/1
--
CREATE OR REPLACE FUNCTION content_item__del(
   delete__item_id integer
) RETURNS integer AS $$
DECLARE
  v_revision_val record;
  v_child_val record;
BEGIN
  --
  -- Delete all revisions of this item
  --
  -- The following loop could be dropped / replaced by a cascade
  -- operation, when proper foreign keys are used along the
  -- inheritance path.
  --
  for v_revision_val in select revision_id 
                        from   cr_revisions
                        where  item_id = delete__item_id 
  LOOP
    PERFORM acs_object__delete(v_revision_val.revision_id);
  end loop;

  --
  -- Delete all children of this item via a recursive call.
  --
  -- The following loop is just needed to delete the revisions of
  -- child items. It could be removed, when proper foreign keys are
  -- used along the inheritance path of cr_content_revisions (which is
  -- not enforced and not always the case).
  --
  for v_child_val in select item_id
                      from   cr_items
                      where  parent_id = delete__item_id 
  LOOP     
     PERFORM content_item__delete(v_child_val.item_id);
  end loop; 

  --
  -- Finally, delete the acs_object of the item.
  --
  PERFORM acs_object__delete(delete__item_id);

  return 0; 
END;
$$ LANGUAGE plpgsql;



select define_function_args('content_item__delete','item_id');
--
-- procedure content_item__delete/1
--
CREATE OR REPLACE FUNCTION content_item__delete(
   delete__item_id integer
) RETURNS integer AS $$
DECLARE
BEGIN
   PERFORM content_item__del (delete__item_id);
   return 0; 
END;
$$ LANGUAGE plpgsql;



select define_function_args('content_item__edit_name','item_id,name');
--
-- procedure content_item__edit_name/2
--
CREATE OR REPLACE FUNCTION content_item__edit_name(
   edit_name__item_id integer,
   edit_name__name varchar
) RETURNS integer AS $$
DECLARE
  exists_id                      integer;       
BEGIN
  select
    item_id
  into 
    exists_id
  from 
    cr_items
  where
    name = edit_name__name
  and 
    parent_id = (select 
	           parent_id
		 from
		   cr_items
		 where
		   item_id = edit_name__item_id);
  if NOT FOUND then
    update cr_items
      set name = edit_name__name
      where item_id = edit_name__item_id;

    update acs_objects
      set title = edit_name__name
      where object_id = edit_name__item_id;
  else
    if exists_id != edit_name__item_id then
      raise EXCEPTION '-20000: An item with the name % already exists in this directory.', edit_name__name;
    end if;
  end if;

  return 0; 
END;
$$ LANGUAGE plpgsql;


select define_function_args('content_item__get_id','item_path,root_folder_id;null,resolve_index;f');
--
-- procedure content_item__get_id/3
--
CREATE OR REPLACE FUNCTION content_item__get_id(
   get_id__item_path varchar,
   get_id__root_folder_id integer, -- default null
   get_id__resolve_index boolean   -- default 'f'

) RETURNS integer AS $$
DECLARE
  v_item_path                    varchar; 
  v_root_folder_id               cr_items.item_id%TYPE;
  get_id__parent_id              integer;       
  child_id                       integer;       
  start_pos                      integer default 1;        
  end_pos                        integer;       
  counter                        integer default 1;
  item_name                      varchar;  
BEGIN

  if get_id__root_folder_id is null then
    select c_root_folder_id from content_item_globals into v_root_folder_id;
  else
    v_root_folder_id := get_id__root_folder_id;
  end if;

  -- If the request path is the root, then just return the root folder
  if get_id__item_path = '/' then
    return v_root_folder_id;
  end if;  

  -- Remove leading, trailing spaces, leading slashes
  v_item_path := rtrim(ltrim(trim(get_id__item_path), '/'), '/');

  get_id__parent_id := v_root_folder_id;

  -- if parent_id is a symlink, resolve it
  get_id__parent_id := content_symlink__resolve(get_id__parent_id);

  LOOP

    end_pos := instr(v_item_path, '/', 1, counter);

    if end_pos = 0 then
      item_name := substr(v_item_path, start_pos);
    else
      item_name := substr(v_item_path, start_pos, end_pos - start_pos);
      counter := counter + 1;
    end if;

    select 
      item_id into child_id
    from 
      cr_items
    where
      parent_id = get_id__parent_id
    and
      name = item_name;

    if NOT FOUND then 
       return null;
    end if;

    exit when end_pos = 0;

    get_id__parent_id := child_id;

    -- if parent_id is a symlink, resolve it
    get_id__parent_id := content_symlink__resolve(get_id__parent_id);

    start_pos := end_pos + 1;
      
  end loop;

  if get_id__resolve_index = 't' then

    -- if the item is a folder and has an index page, then return

    if content_folder__is_folder(child_id ) = 't' and
      content_folder__get_index_page(child_id) is not null then 

      child_id := content_folder__get_index_page(child_id);
    end if;

  end if;

  return child_id;

END;
$$ LANGUAGE plpgsql stable;


--
-- procedure content_item__get_path/2
--

select define_function_args('content_item__get_path','item_id,root_folder_id;null');

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


-- I hard code the content_item_globals.c_root_folder_id here
select define_function_args('content_item__get_virtual_path','item_id,root_folder_id;-100');
--
-- procedure content_item__get_virtual_path/2
--
CREATE OR REPLACE FUNCTION content_item__get_virtual_path(
   get_virtual_path__item_id integer,
   get_virtual_path__root_folder_id integer -- default content_item_globals.c_root_folder_id -- default '-100'

) RETURNS varchar AS $$
DECLARE
  v_path                                  varchar; 
  v_item_id                               cr_items.item_id%TYPE;
  v_is_folder                             boolean;       
  v_index                                 cr_items.item_id%TYPE;
BEGIN
  -- XXX possible bug: root_folder_id arg is ignored.

  -- first resolve the item
  v_item_id := content_symlink__resolve(get_virtual_path__item_id);

  v_is_folder := content_folder__is_folder(v_item_id);
  v_index := content_folder__get_index_page(v_item_id);

  -- if the folder has an index page
  if v_is_folder = 't' and v_index is not null then
    v_path := content_item__get_path(content_symlink__resolve(v_index),null);
  else
    v_path := content_item__get_path(v_item_id,null);
  end if;

  return v_path;
 
END;
$$ LANGUAGE plpgsql;



select define_function_args('content_item__write_to_file','item_id,root_path');
--
-- procedure content_item__write_to_file/2
--
CREATE OR REPLACE FUNCTION content_item__write_to_file(
   item_id integer,
   root_path varchar
) RETURNS integer AS $$
DECLARE
  -- blob_loc               cr_revisions.content%TYPE;
  -- v_revision             cr_items.live_revision%TYPE;
BEGIN
  
  -- FIXME:
  raise NOTICE 'not implemented for postgresql';
/*
  v_revision := content_item__get_live_revision(item_id);

  select content into blob_loc from cr_revisions 
    where revision_id = v_revision;

  if NOT FOUND then 
    raise EXCEPTION '-20000: No live revision for content item % in content_item.write_to_file.', item_id;    
  end if;
  
  PERFORM blob_to_file(root_path || content_item__get_path(item_id), blob_loc);
*/
  return 0; 
END;
$$ LANGUAGE plpgsql;


select define_function_args('content_item__register_template','item_id,template_id,use_context');
--
-- procedure content_item__register_template/3
--
CREATE OR REPLACE FUNCTION content_item__register_template(
   register_template__item_id integer,
   register_template__template_id integer,
   register_template__use_context varchar
) RETURNS integer AS $$
DECLARE
                                        
BEGIN

 -- register template if it is not already registered
  insert into cr_item_template_map
  select
    register_template__item_id as item_id,
    register_template__template_id as template_id,
    register_template__use_context as use_context
  from
    dual
  where
    not exists ( select 1
                 from
                   cr_item_template_map
                 where
                   item_id = register_template__item_id
                 and
                   template_id = register_template__template_id
                 and
                   use_context = register_template__use_context );

  return 0; 
END;
$$ LANGUAGE plpgsql;



select define_function_args('content_item__unregister_template','item_id,template_id;null,use_context;null');
--
-- procedure content_item__unregister_template/3
--
CREATE OR REPLACE FUNCTION content_item__unregister_template(
   unregister_template__item_id integer,
   unregister_template__template_id integer, -- default null
   unregister_template__use_context varchar  -- default null

) RETURNS integer AS $$
DECLARE
                                        
BEGIN

  if unregister_template__use_context is null and 
     unregister_template__template_id is null then

    delete from cr_item_template_map
      where item_id = unregister_template__item_id;

  else if unregister_template__use_context is null then

    delete from cr_item_template_map
      where template_id = unregister_template__template_id
      and item_id = unregister_template__item_id;

  else if unregister_template__template_id is null then

    delete from cr_item_template_map
      where item_id = unregister_template__item_id
      and use_context = unregister_template__use_context;

  else

    delete from cr_item_template_map
      where template_id = unregister_template__template_id
      and item_id = unregister_template__item_id
      and use_context = unregister_template__use_context;

  end if; end if; end if;

  return 0; 
END;
$$ LANGUAGE plpgsql;


select define_function_args('content_item__get_template','item_id,use_context');
--
-- procedure content_item__get_template/2
--
CREATE OR REPLACE FUNCTION content_item__get_template(
   get_template__item_id integer,
   get_template__use_context varchar
) RETURNS integer AS $$
DECLARE
  v_template_id                        cr_templates.template_id%TYPE;
  v_content_type                       cr_items.content_type%TYPE;
BEGIN

  -- look for a template assigned specifically to this item
  select
    template_id 
  into 
     v_template_id
  from
    cr_item_template_map
  where
    item_id = get_template__item_id
  and
    use_context = get_template__use_context;
  -- otherwise get the default for the content type
  if NOT FOUND then
    select 
      m.template_id
    into 
      v_template_id
    from
      cr_items i, cr_type_template_map m
    where
      i.item_id = get_template__item_id
    and
      i.content_type = m.content_type
    and
      m.use_context = get_template__use_context
    and
      m.is_default = 't';

    if NOT FOUND then
       return null;
    end if;
  end if;

  return v_template_id;
 
END;
$$ LANGUAGE plpgsql stable strict;


select define_function_args('content_item__get_content_type','item_id');
--
-- procedure content_item__get_content_type/1
--
CREATE OR REPLACE FUNCTION content_item__get_content_type(
   get_content_type__item_id integer
) RETURNS varchar AS $$
DECLARE
  v_content_type                           cr_items.content_type%TYPE;
BEGIN

  select
    content_type into v_content_type
  from 
    cr_items
  where 
    item_id = get_content_type__item_id;  

  return v_content_type;
 
END;
$$ LANGUAGE plpgsql stable strict;



select define_function_args('content_item__get_live_revision','item_id');
--
-- procedure content_item__get_live_revision/1
--
CREATE OR REPLACE FUNCTION content_item__get_live_revision(
   get_live_revision__item_id integer
) RETURNS integer AS $$
DECLARE
  v_revision_id                             acs_objects.object_id%TYPE;
BEGIN

  select
    live_revision into v_revision_id
  from
    cr_items
  where
    item_id = get_live_revision__item_id;

  return v_revision_id;
 
END;
$$ LANGUAGE plpgsql stable strict;


select define_function_args('content_item__set_live_revision','revision_id,publish_status;ready,publish_date;now(),is_latest;f');
--
-- procedure content_item__set_live_revision/1,2,3,4
--
CREATE OR REPLACE FUNCTION content_item__set_live_revision(
   p__revision_id integer,
   p__publish_status varchar default 'ready',
   p__publish_date timestamptz default now(),
   p__is_latest boolean default false
) RETURNS integer AS $$
DECLARE
BEGIN

  if p__is_latest then
    update cr_items
      set
            live_revision = p__revision_id,
    	    publish_status = p__publish_status,
            latest_revision = p__revision_id   
      where
	    item_id = (select item_id
               from   cr_revisions
               where  revision_id = p__revision_id);
  else
    update cr_items
      set
            live_revision = p__revision_id,
    	    publish_status = p__publish_status
      where
	    item_id = (select item_id
               from   cr_revisions
               where  revision_id = p__revision_id);
  end if;
   
  update cr_revisions
  set
    publish_date = p__publish_date
  where
    revision_id = p__revision_id;

  return 0; 
END;
$$ LANGUAGE plpgsql;


select define_function_args('content_item__unset_live_revision','item_id');
--
-- procedure content_item__unset_live_revision/1
--
CREATE OR REPLACE FUNCTION content_item__unset_live_revision(
   unset_live_revision__item_id integer
) RETURNS integer AS $$
DECLARE
BEGIN

  update
    cr_items
  set
    live_revision = NULL
  where
    item_id = unset_live_revision__item_id;

  -- if an items publish status is "live", change it to "ready"
  update
    cr_items
  set
    publish_status = 'production'
  where
    publish_status = 'live'
  and
    item_id = unset_live_revision__item_id;

  return 0; 
END;
$$ LANGUAGE plpgsql;



select define_function_args('content_item__set_release_period','item_id,start_when;null,end_when;null');
--
-- procedure content_item__set_release_period/3
--
CREATE OR REPLACE FUNCTION content_item__set_release_period(
   set_release_period__item_id integer,
   set_release_period__start_when timestamptz, -- default null
   set_release_period__end_when timestamptz    -- default null

) RETURNS integer AS $$
DECLARE
  v_count                                    integer;       
BEGIN

  select count(*) into v_count from cr_release_periods 
    where item_id = set_release_period__item_id;

  if v_count = 0 then
    insert into cr_release_periods (
      item_id, start_when, end_when
    ) values (
      set_release_period__item_id, 
      set_release_period__start_when, 
      set_release_period__end_when
    );
  else
    update cr_release_periods
      set start_when = set_release_period__start_when,
      end_when = set_release_period__end_when
    where
      item_id = set_release_period__item_id;
  end if;

  return 0; 
END;
$$ LANGUAGE plpgsql;


select define_function_args('content_item__get_revision_count','item_id');
--
-- procedure content_item__get_revision_count/1
--
CREATE OR REPLACE FUNCTION content_item__get_revision_count(
   get_revision_count__item_id integer
) RETURNS integer AS $$
DECLARE
  v_count                       integer;       
BEGIN

  select
    count(*) into v_count
  from 
    cr_revisions
  where
    item_id = get_revision_count__item_id;

  return v_count;
 
END;
$$ LANGUAGE plpgsql stable;


select define_function_args('content_item__get_context','item_id');
--
-- procedure content_item__get_context/1
--
CREATE OR REPLACE FUNCTION content_item__get_context(
   get_context__item_id integer
) RETURNS integer AS $$
DECLARE
  v_context_id                        acs_objects.context_id%TYPE;
BEGIN

  select
    context_id
  into
    v_context_id
  from
    acs_objects
  where
    object_id = get_context__item_id;

  if NOT FOUND then 
     raise EXCEPTION '-20000: Content item % does not exist in content_item.get_context', get_context__item_id;
  end if;

  return v_context_id;
 
END;
$$ LANGUAGE plpgsql stable;


-- 1) make sure we are not moving the item to an invalid location:
--   that is, the destination folder exists and is a valid folder
-- 2) make sure the content type of the content item is registered
--   to the target folder
-- 3) update the parent_id for the item


select define_function_args('content_item__move','item_id,target_folder_id,name');
--
-- procedure content_item__move/3
--
CREATE OR REPLACE FUNCTION content_item__move(
   move__item_id integer,
   move__target_folder_id integer,
   move__name varchar default null
) RETURNS integer AS $$
DECLARE
BEGIN

  if move__target_folder_id is null then 
	raise exception 'attempt to move item_id % to null folder_id', move__item_id;
  end if;

  if content_folder__is_folder(move__item_id) = 't' then

    PERFORM content_folder__move(move__item_id, move__target_folder_id);

  elsif content_folder__is_folder(move__target_folder_id) = 't' then
   

    if content_folder__is_registered(move__target_folder_id,
          content_item__get_content_type(move__item_id),'f') = 't' and
       content_folder__is_registered(move__target_folder_id,
          content_item__get_content_type(content_symlink__resolve(move__item_id)),'f') = 't'
      then
    -- update the parent_id for the item

    update cr_items 
      set parent_id = move__target_folder_id,
          name = coalesce(move__name, name)
      where item_id = move__item_id;
    end if;

    if move__name is not null then
      update acs_objects
        set title = move__name
        where object_id = move__item_id;
    end if;

  end if;

  return 0; 
END;
$$ LANGUAGE plpgsql;


select define_function_args('content_item__generic_move','item_id,target_item_id,name');
--
-- procedure content_item__generic_move/3
--
CREATE OR REPLACE FUNCTION content_item__generic_move(
   move__item_id integer,
   move__target_item_id integer,
   move__name varchar
) RETURNS integer AS $$
DECLARE
BEGIN

  if move__target_item_id is null then 
	raise exception 'attempt to move item_id % to null folder_id', move__item_id;
  end if;

  if content_folder__is_folder(move__item_id) = 't' then

    PERFORM content_folder__move(move__item_id, move__target_item_id);

  elsif content_folder__is_folder(move__target_item_id) = 't' then

    if content_folder__is_registered(move__target_item_id,
          content_item__get_content_type(move__item_id),'f') = 't' and
       content_folder__is_registered(move__target_item_id,
          content_item__get_content_type(content_symlink__resolve(move__item_id)),'f') = 't'
      then
    end if;
  end if;

  -- update the parent_id for the item

  update cr_items 
    set parent_id = move__target_item_id,
        name = coalesce(move__name, name)
    where item_id = move__item_id;

  -- GN: the following "end if" appears to be not needed
  -- end if;

  if move__name is not null then
    update acs_objects
      set title = move__name
      where object_id = move__item_id;
  end if;

  return 0; 
END;
$$ LANGUAGE plpgsql;


-- copy a content item to a target folder
-- 1) make sure we are not copying the item to an invalid location:
--   that is, the destination folder exists, is a valid folder,
--   and is not the current folder
-- 2) make sure the content type of the content item is registered
--   with the current folder
-- 3) create a new item with no revisions in the target folder
-- 4) copy the latest revision from the original item to the new item (if any)


select define_function_args('content_item__copy2','item_id,target_folder_id,creation_user,creation_ip;null');
--
-- procedure content_item__copy2/4
--
CREATE OR REPLACE FUNCTION content_item__copy2(
   copy2__item_id integer,
   copy2__target_folder_id integer,
   copy2__creation_user integer,
   copy2__creation_ip varchar -- default null

) RETURNS integer AS $$
DECLARE
BEGIN

	perform content_item__copy (
		copy2__item_id,
		copy2__target_folder_id,
		copy2__creation_user,
		copy2__creation_ip,
		null
		);
	return copy2__item_id;

END;
$$ LANGUAGE plpgsql;


select define_function_args('content_item__copy','item_id,target_folder_id,creation_user,creation_ip;null,name;null');
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


select define_function_args('content_item__get_latest_revision','item_id');
--
-- procedure content_item__get_latest_revision/1
--
CREATE OR REPLACE FUNCTION content_item__get_latest_revision(
   get_latest_revision__item_id integer
) RETURNS integer AS $$
DECLARE
  v_revision_id                               integer;
  v_rec                                       record;
BEGIN
  for v_rec in 
  select 
    r.revision_id 
  from 
    cr_revisions r, acs_objects o
  where 
    r.revision_id = o.object_id
  and 
    r.item_id = get_latest_revision__item_id
  order by 
    o.creation_date desc
  LOOP
      v_revision_id := v_rec.revision_id;
      exit;
  end LOOP;

  return v_revision_id;
 
END;
$$ LANGUAGE plpgsql strict stable;


select define_function_args('content_item__get_best_revision','item_id');
--
-- procedure content_item__get_best_revision/1
--
CREATE OR REPLACE FUNCTION content_item__get_best_revision(
   get_best_revision__item_id integer
) RETURNS integer AS $$
DECLARE
  v_revision_id                             cr_revisions.revision_id%TYPE;
BEGIN
    
  select
    coalesce(live_revision, latest_revision )
  into
    v_revision_id
  from
    cr_items
  where
    item_id = get_best_revision__item_id;

  return v_revision_id;
 
END;
$$ LANGUAGE plpgsql stable strict;


select define_function_args('content_item__get_title','item_id,is_live;f');
--
-- procedure content_item__get_title/2
--
CREATE OR REPLACE FUNCTION content_item__get_title(
   get_title__item_id integer,
   get_title__is_live boolean default 'f'

) RETURNS varchar AS $$
DECLARE
  v_title                           cr_revisions.title%TYPE;
  v_content_type                    cr_items.content_type%TYPE;
BEGIN
  
  select content_type into v_content_type from cr_items 
    where item_id = get_title__item_id;

  if v_content_type = 'content_folder' then
    select label into v_title from cr_folders 
      where folder_id = get_title__item_id;
  else if v_content_type = 'content_symlink' then
    select label into v_title from cr_symlinks 
      where symlink_id = get_title__item_id;
  else if v_content_type = 'content_extlink' then
    select label into v_title from cr_extlinks
      where extlink_id = get_title__item_id;            
  else
    if get_title__is_live then
      select
	title into v_title
      from
	cr_revisions r, cr_items i
      where
        i.item_id = get_title__item_id
      and
        r.revision_id = i.live_revision;
    else
      select
	title into v_title
      from
	cr_revisions r, cr_items i
      where
        i.item_id = get_title__item_id
      and
        r.revision_id = i.latest_revision;
    end if;
  end if; end if; end if;

  return v_title;

END;
$$ LANGUAGE plpgsql stable;



select define_function_args('content_item__get_publish_date','item_id,is_live;f');
--
-- procedure content_item__get_publish_date/2
--
CREATE OR REPLACE FUNCTION content_item__get_publish_date(
   get_publish_date__item_id integer,
   get_publish_date__is_live boolean -- default 'f'

) RETURNS timestamptz AS $$
DECLARE
  v_revision_id                            cr_revisions.revision_id%TYPE;
  v_publish_date                           cr_revisions.publish_date%TYPE;
BEGIN

  if get_publish_date__is_live then
    select
	publish_date into v_publish_date
    from
	cr_revisions r, cr_items i
    where
      i.item_id = get_publish_date__item_id
    and
      r.revision_id = i.live_revision;
  else
    select
	publish_date into v_publish_date
    from
	cr_revisions r, cr_items i
    where
      i.item_id = get_publish_date__item_id
    and
      r.revision_id = i.latest_revision;
  end if;

  return v_publish_date;
 
END;
$$ LANGUAGE plpgsql stable;


select define_function_args('content_item__is_subclass','object_type,supertype');
--
-- procedure content_item__is_subclass/2
--
CREATE OR REPLACE FUNCTION content_item__is_subclass(
   is_subclass__object_type varchar,
   is_subclass__supertype varchar
) RETURNS boolean AS $$
DECLARE
  v_subclass_p                        boolean;      
  v_inherit_val                       record;
BEGIN
  select count(*) > 0 into v_subclass_p where exists (
	select 1
          from acs_object_types o, acs_object_types o2
         where o2.object_type = is_subclass__supertype
           and o.object_type = is_subclass__object_type
           and o.tree_sortkey between o2.tree_sortkey and tree_right(o2.tree_sortkey));

  return v_subclass_p;

END;
$$ LANGUAGE plpgsql stable;



select define_function_args('content_item__relate','item_id,object_id,relation_tag;generic,order_n;null,relation_type;cr_item_rel');
--
-- procedure content_item__relate/5
--
CREATE OR REPLACE FUNCTION content_item__relate(
   relate__item_id integer,
   relate__object_id integer,
   relate__relation_tag varchar, -- default 'generic'
   relate__order_n integer,      -- default null
   relate__relation_type varchar -- default 'cr_item_rel'

) RETURNS integer AS $$
DECLARE
  v_content_type                 cr_items.content_type%TYPE;
  v_object_type                  acs_objects.object_type%TYPE;
  v_is_valid                     integer;       
  v_rel_id                       integer;       
  v_package_id                   integer;       
  v_exists                       integer;       
  v_order_n                      cr_item_rels.order_n%TYPE;
BEGIN

  -- check the relationship is valid
  v_content_type := content_item__get_content_type (relate__item_id);
  v_object_type := content_item__get_content_type (relate__object_id);

  select
    count(1) into v_is_valid
  from
    cr_type_relations
  where
    content_item__is_subclass( v_object_type, target_type ) = 't'
  and
    content_item__is_subclass( v_content_type, content_type ) = 't';

  if v_is_valid = 0 then
    raise EXCEPTION '-20000: There is no registered relation type matching this item relation.';
  end if;

  if relate__item_id != relate__object_id then
    -- check that these two items are not related already
    --dbms_output.put_line( 'checking if the items are already related...');
    
    select
      rel_id, 1 into v_rel_id, v_exists
    from
      cr_item_rels
    where
      item_id = relate__item_id
    and
      related_object_id = relate__object_id
    and
      relation_tag = relate__relation_tag;

    if NOT FOUND then
       v_exists := 0;
    end if;
    
    v_package_id := acs_object__package_id(relate__item_id);

    -- if order_n is null, use rel_id (the order the item was related)
    if relate__order_n is null then
      v_order_n := v_rel_id;
    else
      v_order_n := relate__order_n;
    end if;


    -- if relationship does not exist, create it
    if v_exists <> 1 then
      --dbms_output.put_line( 'creating new relationship...');
      v_rel_id := acs_object__new(
        null,
        relate__relation_type,
        now(),
        null,
        null,
        relate__item_id,
        't',
        relate__relation_tag || ': ' || relate__item_id || ' - ' || relate__object_id,
        v_package_id
      );

      insert into cr_item_rels (
        rel_id, item_id, related_object_id, order_n, relation_tag
      ) values (
        v_rel_id, relate__item_id, relate__object_id, v_order_n, 
        relate__relation_tag
      );

    -- if relationship already exists, update it
    else
      --dbms_output.put_line( 'updating existing relationship...');
      update cr_item_rels set
        relation_tag = relate__relation_tag,
        order_n = v_order_n
      where
        rel_id = v_rel_id;

      update acs_objects set
        title = relate__relation_tag || ': ' || relate__item_id || ' - ' || relate__object_id
      where object_id = v_rel_id;
    end if;

  end if;

  return v_rel_id;
 
END;
$$ LANGUAGE plpgsql;



select define_function_args('content_item__unrelate','rel_id');
--
-- procedure content_item__unrelate/1
--
CREATE OR REPLACE FUNCTION content_item__unrelate(
   unrelate__rel_id integer
) RETURNS integer AS $$
DECLARE
BEGIN

  -- delete the relation object
  PERFORM acs_rel__delete(unrelate__rel_id);

  -- delete the row from the cr_item_rels table
  delete from cr_item_rels where rel_id = unrelate__rel_id;

  return 0; 
END;
$$ LANGUAGE plpgsql;



select define_function_args('content_item__is_index_page','item_id,folder_id');
--
-- procedure content_item__is_index_page/2
--
CREATE OR REPLACE FUNCTION content_item__is_index_page(
   is_index_page__item_id integer,
   is_index_page__folder_id integer
) RETURNS boolean AS $$
DECLARE
BEGIN
  if content_folder__get_index_page(is_index_page__folder_id) = is_index_page__item_id then
    return 't';
  else
    return 'f';
  end if;
 
END;
$$ LANGUAGE plpgsql stable;


select define_function_args('content_item__get_parent_folder','item_id');
--
-- procedure content_item__get_parent_folder/1
--
CREATE OR REPLACE FUNCTION content_item__get_parent_folder(
   get_parent_folder__item_id integer
) RETURNS integer AS $$
DECLARE
  v_folder_id                              cr_folders.folder_id%TYPE;
  v_parent_folder_p                        boolean default 'f';       
BEGIN
  v_folder_id := get_parent_folder__item_id;

  while NOT v_parent_folder_p and v_folder_id is not null LOOP

    select
      parent_id, content_folder__is_folder(parent_id) 
    into 
      v_folder_id, v_parent_folder_p
    from
      cr_items
    where
      item_id = v_folder_id;

  end loop; 

  return v_folder_id;
 
END;
$$ LANGUAGE plpgsql stable strict;



-- Trigger to maintain context_id in acs_objects
CREATE OR REPLACE FUNCTION cr_items_update_tr () RETURNS trigger AS $$
BEGIN

  if new.parent_id <> old.parent_id then
    update acs_objects set context_id = new.parent_id
    where object_id = new.item_id;
  end if;

  return new;
END;
$$ LANGUAGE plpgsql;

create trigger cr_items_update_tr after update on cr_items
for each row execute procedure cr_items_update_tr ();


-- Trigger to maintain publication audit trail
CREATE OR REPLACE FUNCTION cr_items_publish_update_tr () RETURNS trigger AS $$
BEGIN
  if new.live_revision <> old.live_revision or
     new.publish_status <> old.publish_status
  then 

    insert into cr_item_publish_audit (
      item_id, old_revision, new_revision, old_status, new_status, publish_date
    ) values (
      new.item_id, old.live_revision, new.live_revision, 
      old.publish_status, new.publish_status,
      now()
    );

  end if;

  return new;

END;
$$ LANGUAGE plpgsql;

create trigger cr_items_publish_update_tr before update on cr_items
for each row execute procedure cr_items_publish_update_tr ();

