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


declare
 attr_id integer;
begin

 content_type.create_type (
   content_type  => 'image',
   supertype     => 'content_revision',
   pretty_name   => 'Image',
   pretty_plural => 'Images',
   table_name	 => 'images',
   id_column     => 'image_id'
 );

 attr_id := content_type.create_attribute (
   content_type   => 'image',
   attribute_name => 'width',
   datatype       => 'integer',
   pretty_name    => 'Width',
   pretty_plural  => 'Widths'
 );

 attr_id := content_type.create_attribute (
   content_type   => 'image',
   attribute_name => 'height',
   datatype       => 'integer',
   pretty_name    => 'Height',
   pretty_plural  => 'Heights'
 );

end;
/
show errors


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
begin

  content_type.register_mime_type(
    content_type => 'image',
    mime_type    => 'image/jpeg'
  );

  content_type.register_mime_type(
    content_type => 'image',
    mime_type    => 'image/gif'
  );

end;
/
show errors
