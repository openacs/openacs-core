-- drop the content-image type from the data model

-- Copyright (C) 20000 ArsDigita Corporation

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

-- unregister mime types from the image type
begin

  content_type.unregister_mime_type(
    content_type => 'image',
    mime_type	 => 'image/jpeg'
  );

  content_type.unregister_mime_type(
    content_type => 'image',
    mime_type	 => 'image/gif'
  );

end;
/
show errors

-- remove image mime types

delete from cr_mime_types where mime_type like 'image%';



-- this should remove the attributes and table related to the 
-- the image type

begin

  content_type.drop_type (
    content_type  => 'image',
    drop_table_p  => 't');

end;
/
show errors


drop package image;
