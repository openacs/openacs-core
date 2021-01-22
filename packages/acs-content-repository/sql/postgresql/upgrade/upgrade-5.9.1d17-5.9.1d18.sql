--
-- procedure content_extlink__new/10
--
CREATE OR REPLACE FUNCTION content_extlink__new(
   new__name varchar,              -- default null
   new__url varchar,
   new__label varchar,             -- default null
   new__description varchar,       -- default null
   new__parent_id integer,
   new__extlink_id integer,        -- default null
   new__creation_date timestamptz, -- default now() -- default 'now'
   new__creation_user integer,     -- default null
   new__creation_ip varchar,       -- default null
   new__package_id integer         -- default null

) RETURNS integer AS $$
DECLARE
  v_extlink_id                cr_extlinks.extlink_id%TYPE;
  v_package_id                acs_objects.package_id%TYPE;
  v_label                     cr_extlinks.label%TYPE;
  v_name                      cr_items.name%TYPE;
BEGIN

  if new__label is null then
    v_label := new__url;
  else
    v_label := new__label;
  end if;

  if new__name is null then
    select nextval('t_acs_object_id_seq') into v_extlink_id from dual;
    v_name := 'link' || v_extlink_id;
  else
    v_name := new__name;
  end if;

  if new__package_id is null then
    v_package_id := acs_object__package_id(new__parent_id);
  else
    v_package_id := new__package_id;
  end if;

  v_extlink_id := content_item__new(
      v_name, 
      new__parent_id,
      new__extlink_id,
      null,
      new__creation_date, 
      new__creation_user, 
      null,
      new__creation_ip, 
      'content_item',
      'content_extlink', 
      null,
      null,
      'text/plain',
      null,      
      null,
      null,  -- data
      null,  -- relation_tag
      'f',   -- is_live      
      'text',
      v_package_id,
      't'    -- with_child_rels
  );

  insert into cr_extlinks
    (extlink_id, url, label, description)
  values
    (v_extlink_id, new__url, v_label, new__description);

  update acs_objects
  set title = v_label
  where object_id = v_extlink_id;

  return v_extlink_id;

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

drop function if exists content_item__new(new__name character varying, new__parent_id integer, new__item_id integer, new__locale character varying, new__creation_date timestamp with time zone, new__creation_user integer, new__context_id integer, new__creation_ip character varying, new__item_subtype character varying, new__content_type character varying, new__title character varying, new__description character varying, new__mime_type character varying, new__nls_language character varying, new__text character varying, new__storage_type character varying, new__package_id integer);
