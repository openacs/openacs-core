-- Data model to support content repository of the ArsDigita
-- Publishing System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Hiro Iwashima (iwashima@mit.edu)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

-- This is to handle images

create table images (
   image_id       integer
                  constraint images_image_id_fk
                  references cr_revisions
                  constraint images_image_id_pk
                  primary key,
   width          integer,
   height         integer
);


begin;

 select content_type__create_type (
   'image',
   'content_revision',
   'Image',
   'Images',
   'images',
   'image_id',
   null
 );

 select content_type__create_attribute (
   'image',
   'width',
   'integer',
   'Width',
   'Widths',
   null,
   null,
   'text'
 );

 select content_type__create_attribute (
   'image',
   'height',
   'integer',
   'Height',
   'Heights',
   null,
   null,
   'text'
 );

end;

-- register MIME types to this content type
begin;

  select content_type__register_mime_type(
    'image',
    'image/jpeg'
  );

  select content_type__register_mime_type(
    'image',
    'image/gif'
  );

end;


-- content-image.sql patch
--
-- adds standard image pl/sql package
--
-- Walter McGinnis (wtem@olywa.net), 2001-09-23
-- based on original photo-album package code by Tom Baginski
--

/*
 Creates a new image
 Binary file stored in file-system
*/

-- DRB: This code has some serious problem, IMO.  It's impossible to derive a new
-- type from "image" and make use of it, for starters.  Photo-album uses two 
-- content types to store a photograph - pa_photo and image.  pa_photo would, in
-- the world of real object-oriented languages, be derived from image and there's
-- really no reason not to do so in the OpenACS object type system.  The current
-- style requires separate content_items and content_revisions for both the 
-- pa_photo extended type and the image base type.  They're only tied together
-- by the coincidence of both being the live revision at the same time.  Delete
-- one or the other and guess what, that association's broken!

-- This is not, to put it mildly, clean.  Nor is it efficient to fill the RDBMS
-- with twice as many objects as you need...

-- The Oracle version does allow a non-image type to be specified, as does my
-- alternative down below.  This needs a little more straightening out.

-- DRB: BLOB issues make it impractical to use package_instantiate_object to create
-- new revisions that contain binary data so a higher-level Tcl API is required rather
-- than the standard package_instantiate_object.  So we don't bother calling define_function_args
-- here.



select define_function_args('image__new','name,parent_id;null,item_id;null,revision_id;null,mime_type;jpeg,creation_user;null,creation_ip;null,relation_tag;null,title;null,description;null,is_live;f,publish_date;now(),path,file_size,height,width,package_id;null');

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



select define_function_args('image__new_revision','item_id,revision_id,title,description,publish_date,mime_type,nls_language,creation_user,creation_ip,height,width,package_id');

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




select define_function_args('image__delete','v_item_id');

--
-- procedure image__delete/1
--
CREATE OR REPLACE FUNCTION image__delete(
   v_item_id integer
) RETURNS integer AS $$
DECLARE
BEGIN

    -- This should take care of deleting revisions, too.
    PERFORM content_item__delete (v_item_id);
    return 0;

END; 
$$ LANGUAGE plpgsql;
