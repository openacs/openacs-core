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
   content_type   => 'image',
   attribute_name => 'width',
   datatype       => 'integer',
   pretty_name    => 'Width',
   pretty_plural  => 'Widths',
   null,
   null,
   'text'
 );

 select content_type__create_attribute (
   content_type   => 'image',
   attribute_name => 'height',
   datatype       => 'integer',
   pretty_name    => 'Height',
   pretty_plural  => 'Heights',
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
