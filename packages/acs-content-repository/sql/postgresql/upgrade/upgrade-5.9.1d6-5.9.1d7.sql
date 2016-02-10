--
-- reduce number of versions of image__new from 4 to 2by using defaults
-- reduce number of versions of image__new_revision from 2 to 1 by using defaults
-- commented differences
--

-- image__new/17
DROP FUNCTION IF EXISTS image__new(varchar,integer,integer,integer,varchar,integer,varchar,varchar,varchar,varchar,boolean,timestamptz,varchar,integer,integer,integer,integer);
DROP FUNCTION IF EXISTS image__new(varchar,integer,integer,integer,varchar,integer,varchar,varchar,varchar,varchar,boolean,timestamptz,varchar,integer,integer,integer);

-- DRB's version image__new/16 (differs in arg type 11ff)
DROP FUNCTION IF EXISTS image__new(varchar,integer,integer,integer,varchar,integer,varchar,varchar,varchar,varchar,varchar,varchar,timestamptz,integer,integer,integer);
DROP FUNCTION IF EXISTS image__new(varchar,integer,integer,integer,varchar,integer,varchar,varchar,varchar,varchar,varchar,varchar,timestamptz,integer,integer);

-- procedure image__new_revision/12
DROP FUNCTION IF EXISTS image__new_revision(integer,integer,varchar,varchar,timestamptz,varchar,varchar,integer,varchar,integer,integer,integer);
DROP FUNCTION IF EXISTS image__new_revision(integer,integer,varchar,varchar,timestamptz,varchar,varchar,integer,varchar,integer,integer);


--
-- procedure image__new/17
--
CREATE OR REPLACE FUNCTION image__new(
   new__name varchar,
   new__parent_id integer,        -- default null
   new__item_id integer,          -- default null
   new__revision_id integer,      -- default null
   new__mime_type varchar,        -- default jpeg
   new__creation_user integer,    -- default null
   new__creation_ip varchar,      -- default null
   new__relation_tag varchar,     -- default null
   new__title varchar,            -- default null
   new__description varchar,      -- default null
   new__is_live boolean,          -- default f
   new__publish_date timestamptz, -- default now()
   new__path varchar,
   new__file_size integer,
   new__height integer,
   new__width integer,
   new__package_id integer default null

) RETURNS integer AS $$
DECLARE

    new__locale          varchar default null;
    new__nls_language	 varchar default null;
    new__creation_date	 timestamptz default current_timestamp;
    new__context_id      integer;	

    v_item_id		 cr_items.item_id%TYPE;
    v_package_id	 acs_objects.package_id%TYPE;
    v_revision_id	 cr_revisions.revision_id%TYPE;
  BEGIN
    new__context_id := new__parent_id;

    if new__package_id is null then
      v_package_id := acs_object__package_id(new__parent_id);
    else
      v_package_id := new__package_id;
    end if;

    v_item_id := content_item__new (
      new__name,
      new__parent_id,
      new__item_id,
      new__locale,
      new__creation_date,
      new__creation_user,	
      new__context_id,
      new__creation_ip,
      'content_item',
      'image',
      null,
      new__description,
      new__mime_type,
      new__nls_language,
      null,
      'file', -- storage_type
      v_package_id
    );

    -- update cr_child_rels to have the correct relation_tag
    update cr_child_rels
    set relation_tag = new__relation_tag
    where parent_id = new__parent_id
    and child_id = new__item_id
    and relation_tag = content_item__get_content_type(new__parent_id) || '-' || 'image';

    v_revision_id := content_revision__new (
      new__title,
      new__description,
      new__publish_date,
      new__mime_type,
      new__nls_language,
      new__path,
      v_item_id,
      new__revision_id,
      new__creation_date,
      new__creation_user,
      new__creation_ip,
      new__file_size,
      v_package_id
    );

    insert into images
    (image_id, height, width)
    values
    (v_revision_id, new__height, new__width);

    -- is_live => 't' not used as part of content_item.new
    -- because content_item.new does not let developer specify revision_id,
    -- revision_id is determined in advance 

    if new__is_live = 't' then
       PERFORM content_item__set_live_revision (v_revision_id);
    end if;

    return v_item_id;
END; 
$$ LANGUAGE plpgsql;


-- DRB's version
--
-- procedure image__new/16
--
-- compared to image_new/17:
--    * has no relation_tag, is_live, path, file_size
--    * but has storage_type, content_type, nls_language

--
CREATE OR REPLACE FUNCTION image__new(
   p_name varchar,
   p_parent_id integer,     -- default null
   p_item_id integer,       -- default null
   p_revision_id integer,   -- default null
   p_mime_type varchar,     -- default jpeg
   p_creation_user integer, -- default null
   p_creation_ip varchar,   -- default null
   p_title varchar,         -- default null
   p_description varchar,   -- default null
   p_storage_type varchar,
   p_content_type varchar,
   p_nls_language varchar,
   p_publish_date timestamptz,
   p_height integer,
   p_width integer,
   p_package_id integer default null

) RETURNS integer AS $$
DECLARE
    v_item_id		 cr_items.item_id%TYPE;
    v_revision_id	 cr_revisions.revision_id%TYPE;
    v_package_id	 acs_objects.package_id%TYPE;
  BEGIN

     if content_item__is_subclass(p_content_type, 'image') = 'f' then
       raise EXCEPTION '-20000: image__new can only be called for an image type'; 
     end if;

    if p_package_id is null then
      v_package_id := acs_object__package_id(p_parent_id);
    else
      v_package_id := p_package_id;
    end if;

    v_item_id := content_item__new (
      p_name,
      p_parent_id,
      p_item_id,
      null,
      current_timestamp,
      p_creation_user,	
      p_parent_id,
      p_creation_ip,
      'content_item',
      p_content_type,
      null,
      null,
      null,
      null,
      null,
      p_storage_type,
      v_package_id
    );

    -- We will let the caller fill in the LOB data or file path.

    v_revision_id := content_revision__new (
      p_title,
      p_description,
      p_publish_date,
      p_mime_type,
      p_nls_language,
      null,            -- text
      v_item_id,
      p_revision_id,
      current_timestamp,
      p_creation_user,
      p_creation_ip,
      null,            -- content_length
      v_package_id
    );

    insert into images
    (image_id, height, width)
    values
    (v_revision_id, p_height, p_width);

    return v_item_id;
END; 
$$ LANGUAGE plpgsql;



--
-- procedure image__new_revision/12
--
CREATE OR REPLACE FUNCTION image__new_revision(
   p_item_id integer,
   p_revision_id integer,
   p_title varchar,
   p_description varchar,
   p_publish_date timestamptz,
   p_mime_type varchar,
   p_nls_language varchar,
   p_creation_user integer,
   p_creation_ip varchar,
   p_height integer,
   p_width integer,
   p_package_id integer default null
) RETURNS integer AS $$
DECLARE
   v_revision_id      integer;
   v_package_id       acs_objects.package_id%TYPE;
BEGIN
    -- We will let the caller fill in the LOB data or file path.

    if p_package_id is null then
      v_package_id := acs_object__package_id(p_item_id);
    else
      v_package_id := p_package_id;
    end if;

    v_revision_id := content_revision__new (
      p_title,
      p_description,
      p_publish_date,
      p_mime_type,
      p_nls_language,
      null,               -- content_length
      p_item_id,
      p_revision_id,
      current_timestamp,
      p_creation_user,
      p_creation_ip,
      null,               -- content_length
      v_package_id
    );

    insert into images
    (image_id, height, width)
    values
    (v_revision_id, p_height, p_width);

    return v_revision_id;
END;
$$ LANGUAGE plpgsql;
