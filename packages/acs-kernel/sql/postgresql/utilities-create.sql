--
-- /packages/acs-kernel/sql/utilities-create.sql
--
-- Useful PL/SQL utility routines.
--
-- @author Jon Salz (jsalz@mit.edu)
-- @creation-date 12 Aug 2000
-- @cvs-id $Id$
--



-- added
select define_function_args('util__multiple_nextval','v_sequence_name,v_count');

--
-- procedure util__multiple_nextval/2
--
CREATE OR REPLACE FUNCTION util__multiple_nextval(
   v_sequence_name varchar,
   v_count integer
) RETURNS varchar AS $$
DECLARE
  a_sequence_values      text default '';
  v_rec                  record;
BEGIN
    for counter in 1..v_count loop
        for v_rec in EXECUTE 'select ' || quote_ident(v_sequence_name) || '.nextval as a_seq_val'
        LOOP
           a_sequence_values := a_sequence_values || '','' || v_rec.a_seq_val;
          exit;
        end loop;
    end loop;

    return substr(a_sequence_values, 2);

END;
$$ LANGUAGE plpgsql;



-- added
select define_function_args('util__logical_negation','true_or_false');

--
-- procedure util__logical_negation/1
--
CREATE OR REPLACE FUNCTION util__logical_negation(
   true_or_false boolean
) RETURNS boolean AS $$
DECLARE
BEGIN
      IF true_or_false is null THEN
        return null;
      ELSE IF true_or_false = 'f' THEN
        return 't';
      ELSE
        return 'f';
      END IF; END IF;
END;
$$ LANGUAGE plpgsql immutable strict;


-- added
select define_function_args('util__table_exists','name');

--
-- procedure util__table_exists/1
--
CREATE OR REPLACE FUNCTION util__table_exists(
   name text
) RETURNS boolean AS $$
DECLARE
BEGIN
      return exists (
       select 1 from pg_class
          where relname = name
            and pg_table_is_visible(oid));
END;
$$ LANGUAGE plpgsql;


-- added
select define_function_args('util__table_column_exists','t_name,c_name');

--
-- procedure util__table_column_exists/1
--
CREATE OR REPLACE FUNCTION util__table_column_exists(
   t_name  text,
   c_name text
) RETURNS boolean AS $$
DECLARE
BEGIN
      return exists (
       select 1 from information_schema.columns c
         where c.table_name  = t_name
           and c.column_name = c_name);
END;
$$ LANGUAGE plpgsql;


-- added
select define_function_args('util__view_exists','name');

--
-- procedure util__view_exists/1
--
CREATE OR REPLACE FUNCTION util__view_exists(
   name text
) RETURNS boolean AS $$
DECLARE
BEGIN
      return exists (
       select 1 from pg_views where viewname = name);
END;
$$ LANGUAGE plpgsql;


-- added
select define_function_args('util__index_exists','name');

--
-- procedure util__index_exists/1
--
CREATE OR REPLACE FUNCTION util__index_exists(
   name text
) RETURNS boolean AS $$
DECLARE
BEGIN
      return exists (
       select 1 from pg_indexes where indexname = name);
END;
$$ LANGUAGE plpgsql;


-- added
select define_function_args('util__foreign_key_exists','table,column,reftable,refcolumn');

--
-- procedure util__foreign_key_exists/4
--
CREATE OR REPLACE FUNCTION util__foreign_key_exists(
   p_table text,
   p_column text,
   p_reftable text,
   p_refcolumn text
) RETURNS boolean AS $$
DECLARE
BEGIN
      return exists (
      select 1 from
         information_schema.table_constraints AS tc,
         information_schema.key_column_usage AS kcu,
         information_schema.constraint_column_usage AS ccu
      where tc.constraint_name = kcu.constraint_name
        and tc.constraint_catalog = kcu.constraint_catalog
        and tc.constraint_schema = kcu.constraint_schema
        and tc.table_catalog = kcu.table_catalog
        and tc.table_schema = kcu.table_schema
        and ccu.constraint_name = tc.constraint_name
        and ccu.constraint_catalog = kcu.constraint_catalog
        and ccu.constraint_schema = kcu.constraint_schema
        and ccu.table_catalog = kcu.table_catalog
        and ccu.table_schema = kcu.table_schema
        and tc.constraint_type = 'FOREIGN KEY'
        and tc.table_name   = p_table
        and kcu.column_name = p_column
        and ccu.table_name  = p_reftable
        and ccu.column_name = p_refcolumn);
END;
$$ LANGUAGE plpgsql;

-- added
select define_function_args('util__unique_exists','table,column,single_p;true');

--
-- procedure util__unique_exists/3
--
CREATE OR REPLACE FUNCTION util__unique_exists(
   p_table    text,
   p_column   text,
   p_single_p boolean default true
) RETURNS boolean AS $$
DECLARE
BEGIN
      return exists (select 1
       from
         information_schema.table_constraints AS tc,
         information_schema.key_column_usage  AS kcu
      where tc.constraint_name    = kcu.constraint_name
        and tc.constraint_catalog = kcu.constraint_catalog
        and tc.constraint_schema  = kcu.constraint_schema
        and tc.table_catalog      = kcu.table_catalog
        and tc.table_schema       = kcu.table_schema
        and tc.constraint_type    = 'UNIQUE'
        and tc.table_name   = p_table
        and kcu.column_name = p_column
	and (not p_single_p or (
	   -- this to ensure the constraint involves only one
	   -- column
	   select count(*) from information_schema.key_column_usage
	    where constraint_name    = kcu.constraint_name
	      and constraint_catalog = kcu.constraint_catalog
	      and constraint_schema  = kcu.constraint_schema) = 1));
END;
$$ LANGUAGE plpgsql;

-- added
select define_function_args('util__primary_key_exists','table,column,single_p;true');

--
-- procedure util__unique_exists/3
--
CREATE OR REPLACE FUNCTION util__primary_key_exists(
   p_table    text,
   p_column   text,
   p_single_p boolean default true
) RETURNS boolean AS $$
DECLARE
BEGIN
      return exists (select 1
       from
         information_schema.table_constraints AS tc,
         information_schema.key_column_usage  AS kcu
      where tc.constraint_name    = kcu.constraint_name
        and tc.constraint_catalog = kcu.constraint_catalog
        and tc.constraint_schema  = kcu.constraint_schema
        and tc.table_catalog      = kcu.table_catalog
        and tc.table_schema       = kcu.table_schema
        and tc.constraint_type    = 'PRIMARY KEY'
        and tc.table_name   = p_table
        and kcu.column_name = p_column
	and (not p_single_p or (
	   -- this to ensure the constraint involves only one
	   -- column
	   select count(*) from information_schema.key_column_usage
	    where constraint_name    = kcu.constraint_name
	      and constraint_catalog = kcu.constraint_catalog
	      and constraint_schema  = kcu.constraint_schema) = 1));
END;
$$ LANGUAGE plpgsql;


-- added
select define_function_args('util__not_null_exists','table,column');

--
-- procedure util__not_null_exists/2
--
CREATE OR REPLACE FUNCTION util__not_null_exists(
   p_table    text,
   p_column   text
) RETURNS boolean AS $$
DECLARE
BEGIN
      return (
        coalesce((
	select is_nullable = 'NO'
	  from information_schema.columns
	 where table_name  = p_table
	   and column_name = p_column), false));
END;
$$ LANGUAGE plpgsql;

-- added
select define_function_args('util__get_default','table,column');

--
-- procedure util__get_default/2
--
CREATE OR REPLACE FUNCTION util__get_default(
   p_table    text,
   p_column   text
) RETURNS information_schema.columns.column_default%TYPE AS $$
DECLARE
BEGIN
      return (
	select column_default
	  from information_schema.columns
	 where table_name  = p_table
	   and column_name = p_column);
END;
$$ LANGUAGE plpgsql;

-- added
select define_function_args('util__get_primary_keys','table');

--
-- procedure util__get_primary_keys/1
--
CREATE OR REPLACE FUNCTION util__get_primary_keys(text) RETURNS SETOF pg_attribute.attname%TYPE AS $$
  SELECT a.attname
    FROM pg_index i
    JOIN pg_attribute a ON a.attrelid = i.indrelid
                       AND a.attnum = ANY(i.indkey)
  WHERE i.indrelid = $1::regclass
    AND i.indisprimary;
$$ LANGUAGE sql;
