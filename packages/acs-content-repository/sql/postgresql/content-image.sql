-- Data model to support content repository of the ArsDigita
-- Publishing System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Hiro Iwashima (iwashima@mit.edu)

-- $ID$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

-- This is to handle images

create table images (
   image_id       integer
                  constraint images_image_id_fk
                  references cr_revisions
                  constraint images_pk
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


-- insert new MIME types
insert into cr_mime_types (
  label, mime_type, file_extension
) values (
  'Image - Jpeg', 'image/jpeg','jpg'
);

insert into cr_mime_types (
  label, mime_type, file_extension
) values (
  'Image - Gif', 'image/gif','gif'
);



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

create function image__new (varchar,integer,integer,integer,varchar,integer,varchar,varchar,varchar,varchar,boolean,timestamp,varchar,integer,integer,integer
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

    new__locale          varchar default null;
    new__nls_language	 varchar default null;
    new__creation_date	 timestamp default now();
    new__context_id      integer;	

    v_item_id		 cr_items.item_id%TYPE;
    v_revision_id	 cr_revisions.revision_id%TYPE;
  begin
    new__context_id := new__parent_id;

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
      new__title,
      new__description,
      new__mime_type,
      new__nls_language,
      null,
      ''file'' -- storage_type
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
      new__creation_ip
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

create function image__delete (integer)
returns integer as '
declare
  v_item_id		alias $1;
  v_revision_id		integer;
      -- order by used in cursur so latest revision will be deleted last
      -- save resetting latest revision multiple times during delete process
begin
    for v_revision_id in select
        revision_id
      from
        cr_revisions
      where
        item_id = v_item_id
      order by revision_id asc
    loop
      PERFORM content_revision__delete_revision (
        v_revision_id
      );
    end loop;

    PERFORM content_item__delete (v_item_id);
    return 1;
end; ' language 'plpgsql';

