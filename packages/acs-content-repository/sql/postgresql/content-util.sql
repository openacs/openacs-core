-- Data model to support content repository of the ArsDigita
-- Publishing System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

create function table_exists (varchar)
returns boolean as '
declare
        table_exists__table_name             alias for $1;  
begin

        return count(*) > 0
          from pg_class 
         where relname = lower(table_exists__table_name);
 
end;' language 'plpgsql' stable strict;

create or replace function column_exists (varchar,varchar)
returns boolean as '
declare
        column_exists__table_name             alias for $1;  
        column_exists__column_name            alias for $2;  
begin

        return count(*) > 0
          from pg_class c, pg_attribute a
         where c.relname = lower(column_exists__table_name)
           and c.oid = a.attrelid
           and a.attname = lower(column_exists__column_name);

end;' language 'plpgsql' stable;

create or replace function trigger_exists (varchar,varchar) returns boolean as '
declare 
        trigger_name    alias for $1;
        on_table        alias for $2;
begin
        return count(*) > 0
          from pg_class c, pg_trigger t
         where c.relname = lower(on_table)
           and c.oid = t.tgrelid
           and t.tgname = lower(trigger_name);

end;' language 'plpgsql' stable;

create or replace function trigger_func_exists (varchar) returns boolean as '
declare 
        trigger_name    alias for $1;
begin
        return count(*) = 1
          from pg_proc
         where proname = lower(trigger_name)
           and pronargs = 0;

end;' language 'plpgsql' stable;

create or replace function rule_exists (varchar,varchar) returns boolean as '
declare
        rule_name       alias for $1;
        table_name      alias for $2;
begin
        return count(*) = 1
          from pg_rules
         where tablename::varchar = lower(table_name)
           and rulename::varchar = lower(rule_name);

end;' language 'plpgsql' stable;

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
