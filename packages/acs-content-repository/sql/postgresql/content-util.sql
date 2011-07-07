-- Data model to support content repository of the ArsDigita
-- Publishing System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html



-- added
select define_function_args('table_exists','table_name');

--
-- procedure table_exists/1
--
CREATE OR REPLACE FUNCTION table_exists(
   table_exists__table_name varchar
) RETURNS boolean AS $$
DECLARE
BEGIN

        return count(*) > 0
          from pg_class 
         where relname = lower(table_exists__table_name);
 
END;
$$ LANGUAGE plpgsql stable strict;



-- added
select define_function_args('column_exists','table_name,column_name');

--
-- procedure column_exists/2
--
CREATE OR REPLACE FUNCTION column_exists(
   column_exists__table_name varchar,
   column_exists__column_name varchar
) RETURNS boolean AS $$
DECLARE
BEGIN

        return count(*) > 0
          from pg_class c, pg_attribute a
         where c.relname = lower(column_exists__table_name)
           and c.oid = a.attrelid
           and a.attname = lower(column_exists__column_name);

END;
$$ LANGUAGE plpgsql stable;



-- added
select define_function_args('trigger_exists','trigger_name,on_table');

--
-- procedure trigger_exists/2
--
CREATE OR REPLACE FUNCTION trigger_exists(
   trigger_name varchar,
   on_table varchar
) RETURNS boolean AS $$
DECLARE 
BEGIN
        return count(*) > 0
          from pg_class c, pg_trigger t
         where c.relname = lower(on_table)
           and c.oid = t.tgrelid
           and t.tgname = lower(trigger_name);

END;
$$ LANGUAGE plpgsql stable;



-- added
select define_function_args('trigger_func_exists','trigger_name');

--
-- procedure trigger_func_exists/1
--
CREATE OR REPLACE FUNCTION trigger_func_exists(
   trigger_name varchar
) RETURNS boolean AS $$
DECLARE 
BEGIN
        return count(*) = 1
          from pg_proc
         where proname = lower(trigger_name)
           and pronargs = 0;

END;
$$ LANGUAGE plpgsql stable;



-- added
select define_function_args('rule_exists','rule_name,table_name');

--
-- procedure rule_exists/2
--
CREATE OR REPLACE FUNCTION rule_exists(
   rule_name varchar,
   table_name varchar
) RETURNS boolean AS $$
DECLARE
BEGIN
        return count(*) = 1
          from pg_rules
         where tablename::varchar = lower(table_name)
           and rulename::varchar = lower(rule_name);

END;
$$ LANGUAGE plpgsql stable;

