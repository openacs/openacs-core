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

