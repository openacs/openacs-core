--
-- Note: some of the update operations might take on large sites a
-- couple of minutes, since these operate on the largest tables of
-- OpenACS. You might consider to run this on production offline or
-- with a proxy turned off.
--
-- Make sure there are no stray entries in cr_child_rels
--

DROP FUNCTION IF EXISTS content_item__new(character varying,integer,integer,character varying,timestamp with time zone,integer,integer,character varying,character varying,character varying,character varying,text,character varying,character varying,character varying,text,character varying,boolean,character varying,integer,boolean);
DROP FUNCTION IF EXISTS content_item__new(character varying,integer,integer,character varying,timestamp with time zone,integer,integer,character varying,character varying,character varying,character varying,text,character varying,character varying,character varying,text,character varying,boolean,character varying,integer);

DROP FUNCTION IF EXISTS content_item__new(varchar,integer,integer,varchar,timestamptz,integer,integer,varchar,varchar,varchar,varchar,varchar,varchar,varchar,integer,integer,boolean);
DROP FUNCTION IF EXISTS content_item__new(varchar,integer,integer,varchar,timestamptz,integer,integer,varchar,varchar,varchar,varchar,varchar,varchar,varchar,integer,integer);
DROP FUNCTION IF EXISTS content_item__new(varchar,integer,integer,varchar,timestamptz,integer,integer,varchar,varchar,varchar,varchar,varchar,varchar,varchar,integer);

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
   new__storage_type varchar,      -- check in ('text','file')
   new__package_id integer default null

) RETURNS integer AS $$
--
-- content_item__new/17 is deprecated, one should call /21
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
DROP FUNCTION IF EXISTS content_item__new(varchar, integer, varchar, text, text, integer);
DROP FUNCTION IF EXISTS content_item__new(varchar, integer, varchar, text, text);

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


DROP FUNCTION IF EXISTS content_item__copy(integer,integer,integer,varchar,varchar);
DROP FUNCTION IF EXISTS content_item__copy(integer,integer,integer,varchar);

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


DROP FUNCTION IF EXISTS content_item__get_title(integer,boolean);
DROP FUNCTION IF EXISTS content_item__get_title(integer);

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


DROP FUNCTION IF EXISTS content_item__move(integer,integer,varchar);
DROP FUNCTION IF EXISTS content_item__move(integer,integer);

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

