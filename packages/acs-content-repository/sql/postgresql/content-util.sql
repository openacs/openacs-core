-- Data model to support content repository of the ArsDigita
-- Publishing System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

-- or replace  function
create function table_exists (varchar)
returns boolean as '
declare
  table_exists__table_name             alias for $1;  
  v_exists                             boolean;       
                                        
begin

  select count(*) > 0 into v_exists 
    from pg_class 
   where upper(relname) = upper(table_exists__table_name);

  return v_exists;
 
end;' language 'plpgsql';


end table_exists;

-- show errors

-- or replace  function
create function column_exists (varchar,varchar)
returns boolean as '
declare
  column_exists__table_name             alias for $1;  
  column_exists__column_name            alias for $2;  
  v_exists                              boolean;       
begin

 select count(*) > 0 into v_exists
   from pg_class c, pg_attribute a
  where upper(c.relname) = = upper(column_exists__table_name)
    and c.oid = a.attrelid
    and upper(a.attname) = upper(column_exists__column_name);

  return v_exists;

end;' language 'plpgsql';


-- java stuff, deal with this later.

/*
create or replace procedure clob_to_blob(
  clob_loc clob, blob_loc blob) 
as language 
  java 
name 
  'com.arsdigita.content.Util.clobToBlob(
    oracle.sql.CLOB, oracle.sql.BLOB
   )';
/
show errors

create or replace procedure blob_to_clob(
  blob_loc blob, clob_loc clob) 
as language 
  java 
name 
  'com.arsdigita.content.Util.blobToClob(
    oracle.sql.BLOB, oracle.sql.CLOB
   )';
/
show errors


create or replace procedure string_to_blob(
  s varchar2, blob_loc blob) 
as language 
  java 
name 
  'com.arsdigita.content.Util.stringToBlob(
    java.lang.String, oracle.sql.BLOB
   )';
/
show errors

create or replace procedure string_to_blob_size(
  s varchar2, blob_loc blob, blob_size number) 
as language 
  java 
name 
  'com.arsdigita.content.Util.stringToBlob(
    java.lang.String, oracle.sql.BLOB, int
   )';
/
show errors

create or replace function blob_to_string(
  blob_loc blob) return varchar2
as language 
  java 
name 
  'com.arsdigita.content.Util.blobToString(
    oracle.sql.BLOB
   ) return java.lang.String';
/
show errors

create or replace procedure blob_to_file(
s varchar2, blob_loc blob)
as language
  java
name
  'com.arsdigita.content.Util.blobToFile(
  java.lang.String, oracle.sql.BLOB
  )';
/
show errors
*/
