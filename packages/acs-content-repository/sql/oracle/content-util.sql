-- Data model to support content repository of the ArsDigita
-- Publishing System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

create or replace function table_exists (
  table_name varchar2
) return boolean is

  v_count integer;
  v_exists boolean;

begin

  select decode(count(*),0,0,1) into v_count 
    from user_tables where table_name = upper(table_exists.table_name);

  if v_count = 1 then
    v_exists := true;
  else
    v_exists := false;
  end if;

  return v_exists;

end table_exists;
/
show errors

create or replace function column_exists (
  table_name varchar2,
  column_name varchar2
) return boolean is

  v_count integer;
  v_exists boolean;

begin

 select decode(count(*),0,0,1) into v_count from user_tab_columns
   where table_name = upper(column_exists.table_name)
   and column_name = upper(column_exists.column_name);

  if v_count = 1 then
    v_exists := true;
  else
    v_exists := false;
  end if;

  return v_exists;

end column_exists;
/
show errors

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
