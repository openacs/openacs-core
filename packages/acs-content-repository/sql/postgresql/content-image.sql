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

create or replace function image__new (varchar,integer,integer,integer,varchar,integer,varchar,varchar,varchar,varchar,boolean,timestamptz,varchar,integer,integer,integer,integer)
returns integer as '
  declare
    new__name		alias for $1;
    new__parent_id	alias for $2; -- default null
    new__item_id	alias for $3; -- default null
    new__revision_id	alias for $4; -- default null
    new__mime_type	alias for $5; -- default jpeg
    new__creation_user  alias for $6; -- default null
    new__creation_ip    alias for $7; -- default null
    new__relation_tag	alias for $8; -- default null
    new__title          alias for $9; -- default null
    new__description    alias for $10; -- default null
    new__is_live        alias for $11; -- default f
    new__publish_date	alias for $12; -- default now()
    new__path   	alias for $13; 
    new__file_size   	alias for $14; 
    new__height    	alias for $15;
    new__width		alias for $16; 
    new__package_id     alias for $17; -- default null

    new__locale          varchar default null;
    new__nls_language	 varchar default null;
    new__creation_date	 timestamptz default current_timestamp;
    new__context_id      integer;	

    v_item_id		 cr_items.item_id%TYPE;
    v_package_id	 acs_objects.package_id%TYPE;
    v_revision_id	 cr_revisions.revision_id%TYPE;
  begin
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
      ''content_item'',
      ''image'',
      null,
      new__description,
      new__mime_type,
      new__nls_language,
      null,
      ''file'', -- storage_type
      v_package_id
    );

    -- update cr_child_rels to have the correct relation_tag
    update cr_child_rels
    set relation_tag = new__relation_tag
    where parent_id = new__parent_id
    and child_id = new__item_id
    and relation_tag = content_item__get_content_type(new__parent_id) || ''-'' || ''image'';

    v_revision_id := content_revision__new (
      new__title,
      new__description,
      new__publish_date,
      new__mime_type,
      new__nls_language,
      null,
      v_item_id,
      new__revision_id,
      new__creation_date,
      new__creation_user,
      new__creation_ip,
      v_package_id
    );

    insert into images
    (image_id, height, width)
    values
    (v_revision_id, new__height, new__width);

    -- update revision with image file info
    update cr_revisions
    set content_length = new__file_size,
    content = new__path
    where revision_id = v_revision_id;

    -- is_live => ''t'' not used as part of content_item.new
    -- because content_item.new does not let developer specify revision_id,
    -- revision_id is determined in advance 

    if new__is_live = ''t'' then
       PERFORM content_item__set_live_revision (v_revision_id);
    end if;

    return v_item_id;
end; ' language 'plpgsql';

create or replace function image__new (varchar,integer,integer,integer,varchar,integer,varchar,varchar,varchar,varchar,boolean,timestamptz,varchar,integer,integer,integer
  ) returns integer as '
  declare
    new__name		alias for $1;
    new__parent_id	alias for $2; -- default null
    new__item_id	alias for $3; -- default null
    new__revision_id	alias for $4; -- default null
    new__mime_type	alias for $5; -- default jpeg
    new__creation_user  alias for $6; -- default null
    new__creation_ip    alias for $7; -- default null
    new__relation_tag	alias for $8; -- default null
    new__title          alias for $9; -- default null
    new__description    alias for $10; -- default null
    new__is_live        alias for $11; -- default f
    new__publish_date	alias for $12; -- default now()
    new__path   	alias for $13; 
    new__file_size   	alias for $14; 
    new__height    	alias for $15;
    new__width		alias for $16; 
  begin
    return image__new(new__name,
                      new__parent_id,
                      new__item_id,
                      new__revision_id,
                      new__mime_type,
                      new__creation_user,
                      new__creation_ip,
                      new__relation_tag,
                      new__title,
                      new__description,
                      new__is_live,
                      new__publish_date,
                      new__path,
                      new__file_size,
                      new__height,
                      new__width,
                      null
    );
end; ' language 'plpgsql';

-- DRB's version

create or replace function image__new (varchar,integer,integer,integer,varchar,integer,varchar,varchar,varchar,varchar,varchar,
                            varchar,timestamptz,integer, integer, integer) returns integer as '
  declare
    p_name              alias for $1;
    p_parent_id         alias for $2; -- default null
    p_item_id           alias for $3; -- default null
    p_revision_id       alias for $4; -- default null
    p_mime_type         alias for $5; -- default jpeg
    p_creation_user     alias for $6; -- default null
    p_creation_ip       alias for $7; -- default null
    p_title             alias for $8; -- default null
    p_description       alias for $9; -- default null
    p_storage_type      alias for $10;
    p_content_type      alias for $11;
    p_nls_language      alias for $12;
    p_publish_date      alias for $13;
    p_height            alias for $14;
    p_width             alias for $15;
    p_package_id        alias for $16; -- default null

    v_item_id		 cr_items.item_id%TYPE;
    v_revision_id	 cr_revisions.revision_id%TYPE;
    v_package_id	 acs_objects.package_id%TYPE;
  begin

     if content_item__is_subclass(p_content_type, ''image'') = ''f'' then
       raise EXCEPTION ''-20000: image__new can only be called for an image type''; 
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
      ''content_item'',
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
      null,
      v_item_id,
      p_revision_id,
      current_timestamp,
      p_creation_user,
      p_creation_ip,
      v_package_id
    );

    insert into images
    (image_id, height, width)
    values
    (v_revision_id, p_height, p_width);

    return v_item_id;
end; ' language 'plpgsql';

create or replace function image__new (varchar,integer,integer,integer,varchar,integer,varchar,varchar,varchar,varchar,varchar,
                            varchar,timestamptz,integer, integer) returns integer as '
  declare
    p_name              alias for $1;
    p_parent_id         alias for $2; -- default null
    p_item_id           alias for $3; -- default null
    p_revision_id       alias for $4; -- default null
    p_mime_type         alias for $5; -- default jpeg
    p_creation_user     alias for $6; -- default null
    p_creation_ip       alias for $7; -- default null
    p_title             alias for $8; -- default null
    p_description       alias for $9; -- default null
    p_storage_type      alias for $10;
    p_content_type      alias for $11;
    p_nls_language      alias for $12;
    p_publish_date      alias for $13;
    p_height            alias for $14;
    p_width             alias for $15;
  begin
    return image__new(p_name,
                      p_parent_id,
                      p_item_id,
                      p_revision_id,
                      p_mime_type,
                      p_creation_user,
                      p_creation_ip,
                      p_title,
                      p_description,
                      p_storage_type,
                      p_content_type,
                      p_nls_language,
                      p_publish_date,
                      p_height,
                      p_width,
                      null
    );
end; ' language 'plpgsql';


create or replace function image__new_revision(integer, integer, varchar, varchar, timestamptz, varchar, varchar,
                                    integer, varchar, integer, integer, integer) returns integer as '
declare
   p_item_id          alias for $1;
   p_revision_id      alias for $2;
   p_title            alias for $3;
   p_description      alias for $4;
   p_publish_date     alias for $5;
   p_mime_type        alias for $6;
   p_nls_language     alias for $7;
   p_creation_user    alias for $8;
   p_creation_ip      alias for $9;
   p_height           alias for $10;
   p_width            alias for $11;
   p_package_id       alias for $12;
   v_revision_id      integer;
   v_package_id       acs_objects.package_id%TYPE;
begin
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
      null,
      p_item_id,
      p_revision_id,
      current_timestamp,
      p_creation_user,
      p_creation_ip,
      v_package_id
    );

    insert into images
    (image_id, height, width)
    values
    (v_revision_id, p_height, p_width);

    return v_revision_id;
end;' language 'plpgsql';

create or replace function image__new_revision(integer,integer,varchar,varchar,timestamptz,varchar,varchar,
                                    integer,varchar,integer,integer) returns integer as '
declare
   p_item_id          alias for $1;
   p_revision_id      alias for $2;
   p_title            alias for $3;
   p_description      alias for $4;
   p_publish_date     alias for $5;
   p_mime_type        alias for $6;
   p_nls_language     alias for $7;
   p_creation_user    alias for $8;
   p_creation_ip      alias for $9;
   p_height           alias for $10;
   p_width            alias for $11;
   v_revision_id      integer;
begin
   return image__new_revision(p_item_id,
                              p_revision_id,
                              p_title,
                              p_description,
                              p_publish_date,
                              p_mime_type,
                              p_nls_language,
                              p_creation_user,
                              p_creation_ip,
                              p_height,
                              p_width,
                              p_revision_id,
                              null
   );

end;' language 'plpgsql';

create or replace function image__delete (integer)
returns integer as '
declare
  v_item_id		alias for $1;
begin

    -- This should take care of deleting revisions, too.
    PERFORM content_item__delete (v_item_id);
    return 0;

end; ' language 'plpgsql';
