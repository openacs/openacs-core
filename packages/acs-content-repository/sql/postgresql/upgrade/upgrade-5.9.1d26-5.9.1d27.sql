-- procedure image__new/16
--
DROP FUNCTION IF EXISTS image__new(character varying,integer,integer,integer,character varying,integer,character varying,character varying,character varying,character varying,boolean,timestamp with time zone,character varying,integer,integer,integer,integer);

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
   p_storage_type cr_items.storage_type%TYPE,
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
-- procedure content_revision__content_copy/2
--
CREATE OR REPLACE FUNCTION content_revision__content_copy(
   content_copy__revision_id integer,
   content_copy__revision_id_dest integer -- default null

) RETURNS integer AS $$
DECLARE
  v_item_id                            cr_items.item_id%TYPE;
  v_content_length                     cr_revisions.content_length%TYPE;
  v_revision_id_dest                   cr_revisions.revision_id%TYPE;
  v_content                            cr_revisions.content%TYPE;
  v_lob                                cr_revisions.lob%TYPE;
  v_new_lob                            cr_revisions.lob%TYPE;
  v_storage_type                       cr_items.storage_type%TYPE;
BEGIN
  if content_copy__revision_id is null then 
	raise exception 'content_revision__content_copy attempt to copy a null revision_id';
  end if;

  select
    content_length, item_id
  into
    v_content_length, v_item_id
  from
    cr_revisions
  where
    revision_id = content_copy__revision_id;

  -- get the destination revision
  if content_copy__revision_id_dest is null then
    select
      latest_revision into v_revision_id_dest
    from
      cr_items
    where
      item_id = v_item_id;
  else
    v_revision_id_dest := content_copy__revision_id_dest;
  end if;


  -- only copy the content if the source content is not null
  if v_content_length is not null and v_content_length > 0 then

    /* The internal LOB types - BLOB, CLOB, and NCLOB - use copy semantics, as 
       opposed to the reference semantics which apply to BFILEs.
       When a BLOB, CLOB, or NCLOB is copied from one row to another row in 
       the same table or in a different table, the actual LOB value is
       copied, not just the LOB locator. */

    select r.content, r.content_length, r.lob, i.storage_type 
      into v_content, v_content_length, v_lob, v_storage_type
      from cr_revisions r, cr_items i 
     where r.item_id = i.item_id 
       and r.revision_id = content_copy__revision_id;

    if v_storage_type = 'lob' then
        v_new_lob := empty_lob();

	PERFORM lob_copy(v_lob, v_new_lob);

        update cr_revisions
           set content = null,
               content_length = v_content_length,
               lob = v_new_lob
         where revision_id = v_revision_id_dest;
	-- this call has to be before the above instruction,
	-- because lob references the v_new_lob 
	--        PERFORM lob_copy(v_lob, v_new_lob);
    else 
        -- this will work for both file and text types... well sort of.
        -- this really just creates a reference to the first file which is
        -- wrong since, the item_id, revision_id uniquely describes the 
        -- location of the file in the content repository file system.  
        -- after copy is called, the content attribute needs to be updated 
        -- with the new relative file path:

        -- update cr_revisions
        -- set content = '[cr_create_content_file $item_id $revision_id [cr_fs_path]$old_rel_path]'
        -- where revision_id = :revision_id
        
        -- old_rel_path is the content attribute value of the content revision
        -- that is being copied.
        update cr_revisions
           set content = v_content,
               content_length = v_content_length,
               lob = null
         where revision_id = v_revision_id_dest;
    end if;

  end if;

  return 0; 
END;
$$ LANGUAGE plpgsql;

--
-- procedure content_revision__get_content/1
--
CREATE OR REPLACE FUNCTION content_revision__get_content(
   get_content__revision_id integer
) RETURNS text AS $$
DECLARE
  v_storage_type                      cr_items.storage_type%TYPE;
  v_lob_id                            integer;
  v_data                              text;
BEGIN
       select i.storage_type, r.lob 
         into v_storage_type, v_lob_id
         from cr_items i, cr_revisions r
        where i.item_id = r.item_id 
          and r.revision_id = get_content__revision_id;
        
        if v_storage_type = 'lob' then
           return v_lob_id::text;
        else 
           return content
             from cr_revisions
            where revision_id = get_content__revision_id;
        end if;

END;
$$ LANGUAGE plpgsql stable strict;
