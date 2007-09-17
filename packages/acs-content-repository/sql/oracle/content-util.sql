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

create or replace function blob_to_string (blob_loc IN BLOB)
RETURN VARCHAR2
IS
v_blength number;
v_ret varchar(32767);
v_amount binary_integer:=10000;
v_offset integer:=1;
v_buffer raw(20000);
BEGIN
  v_blength:=dbms_lob.getlength(blob_loc);
  IF v_blength=0 THEN
   return v_ret;
  ELSE
    if v_blength<v_amount then
      v_amount:=v_blength;
    end if;

    FOR i IN 1..CEIL(v_blength/v_amount) LOOP
      dbms_lob.read(blob_loc,v_amount,v_offset,v_buffer);
      v_ret:=v_ret||utl_raw.cast_to_varchar2(v_buffer);
      v_offset:=v_offset+v_amount;
    END LOOP;

    return v_ret;
  END IF;
END;
/

create or replace procedure string_to_blob (STRING IN VARCHAR2, BLOB_LOC IN OUT BLOB)
IS
v_slength number;
v_ret blob;
v_amount binary_integer:=10000;
v_offset integer:=1;
v_buffer raw(20000);
BEGIN
  v_slength:=length(string);
  IF v_slength = 0 THEN
    blob_loc:=v_ret;
  ELSE
    v_buffer:=utl_raw.cast_to_raw(string);
    v_slength:=utl_raw.length(v_buffer);
    
    IF v_slength<v_amount THEN
      v_amount:=v_slength;
    END IF;

    FOR i IN 1..CEIL(v_slength/v_amount) LOOP
      dbms_lob.write(v_ret,v_amount,v_offset,v_buffer);
      v_offset:=v_offset+v_amount;
    END LOOP;
    blob_loc:=v_ret;
  END IF;
END;
/

create or replace procedure clob_to_blob (CLOB_LOC IN CLOB, BLOB_LOC IN OUT BLOB)
IS
v_clength number;
v_ret BLOB;
v_amount binary_integer:=10000;
v_offset integer:=1;
v_lang_context number:=DBMS_LOB.DEFAULT_LANG_CTX;
v_warning NUMBER;
BEGIN
  v_clength:=dbms_lob.getlength(CLOB_LOC);
  if v_clength<v_amount then
    v_amount:=v_clength;
  end if;
  FOR i IN 1..CEIL(v_clength/v_amount) LOOP
    dbms_lob.converttoblob(v_ret,clob_loc,v_amount,v_offset,v_offset,0,v_lang_context,v_warning);
    v_offset:=v_offset+v_amount;  
  END LOOP;
  blob_loc:=v_ret;
END;
/

create or replace procedure blob_to_clob (BLOB_LOC IN BLOB, CLOB_LOC IN OUT CLOB)
IS
v_blength number;
v_ret CLOB;
v_amount binary_integer:=10000;
v_offset integer:=1;
v_lang_context number:=DBMS_LOB.DEFAULT_LANG_CTX;
v_warning NUMBER;
BEGIN
  if v_blength<v_amount then
    v_amount:=v_blength;
  end if;
  FOR i IN 1..CEIL(v_blength/v_amount) LOOP
    dbms_lob.converttoclob(v_ret,blob_loc,v_amount,v_offset,v_offset,0,v_lang_context,v_warning);
    v_offset:=v_offset+v_amount;  
  END LOOP;
  clob_loc:=v_ret;
END;
/



create or replace procedure blob_to_file (path IN VARCHAR2, BLOB_LOC BLOB)
IS
v_dir varchar2(128);
v_file varchar2(32);
v_blength number;
outfile utl_file.file_type;
v_amount binary_integer:=10000;
v_offset integer:=1;
v_buffer raw(20000);
BEGIN
  v_dir:=substr(path,1,instr(path,'/',-1)-1);
  v_file:=substr(path,instr(path,'/',-1)+1);
  v_blength := dbms_lob.getlength(blob_loc);
  outfile := utl_file.fopen(v_dir, v_file, 'WB');
  if v_blength<v_amount then
    v_amount:=v_blength;
  end if;

  FOR i IN 1..CEIL(v_blength/v_amount) LOOP
    dbms_lob.read(blob_loc,v_amount,v_offset,v_buffer);
    utl_file.put_raw(outfile,v_buffer);
    v_offset:=v_offset+v_amount;
  END LOOP;

  utl_file.fclose(outfile);
END;
/