-- Data model to support content repository of the ArsDigita
-- Publishing System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

/*
create or replace package content is

procedure string_to_blob(
  s varchar2, blob_loc blob) 
as language 
  java 
name 
  'com.arsdigita.content.Util.stringToBlob(
    java.lang.String, oracle.sql.BLOB
   )';

procedure string_to_blob_size(
  s varchar2, blob_loc blob, blob_size number) 
as language 
  java 
name 
  'com.arsdigita.content.Util.stringToBlob(
    java.lang.String, oracle.sql.BLOB, int
   )';

function blob_to_string(
  blob_loc blob) return varchar2
as language 
  java 
name 
  'com.arsdigita.content.Util.blobToString(
    oracle.sql.BLOB
   ) return java.lang.String';

procedure blob_to_file(
s varchar2, blob_loc blob)
as language
  java
name
  'com.arsdigita.content.Util.blobToFile(
  java.lang.String, oracle.sql.BLOB
  )';

end content;
/
show errors
*/
