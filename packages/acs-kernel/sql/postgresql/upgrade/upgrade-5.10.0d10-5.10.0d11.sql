--
-- Make sure that table_name and column_name work
-- case-insensitive (similar to function_args)
--

--
-- procedure util__table_column_exists/1
--
select define_function_args('util__table_column_exists','p_table,p_column');

DROP FUNCTION if exists util__table_column_exists(text,text);
CREATE OR REPLACE FUNCTION util__table_column_exists(
   p_table  text,
   p_column text
) RETURNS boolean AS $$
DECLARE
BEGIN
      return exists (
       select 1 from information_schema.columns c
         where c.table_name  = lower(p_table)
           and c.column_name = lower(p_column));
END;
$$ LANGUAGE plpgsql;


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
        and tc.table_name   = lower(p_table)
        and kcu.column_name = lower(p_column)
        and ccu.table_name  = lower(p_reftable)
        and ccu.column_name = lower(p_refcolumn));
END;
$$ LANGUAGE plpgsql;

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
        and tc.table_name   = lower(p_table)
        and kcu.column_name = lower(p_column)
	and (not p_single_p or (
	   -- this to ensure the constraint involves only one
	   -- column
	   select count(*) from information_schema.key_column_usage
	    where constraint_name    = kcu.constraint_name
	      and constraint_catalog = kcu.constraint_catalog
	      and constraint_schema  = kcu.constraint_schema) = 1));
END;
$$ LANGUAGE plpgsql;

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
        and tc.table_name   = lower(p_table)
        and kcu.column_name = lower(p_column)
	and (not p_single_p or (
	   -- this to ensure the constraint involves only one
	   -- column
	   select count(*) from information_schema.key_column_usage
	    where constraint_name    = kcu.constraint_name
	      and constraint_catalog = kcu.constraint_catalog
	      and constraint_schema  = kcu.constraint_schema) = 1));
END;
$$ LANGUAGE plpgsql;


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
	 where table_name  = lower(p_table)
	   and column_name = lower(p_column)), false));
END;
$$ LANGUAGE plpgsql;


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
	 where table_name  = lower(p_table)
	   and column_name = lower(p_column));
END;
$$ LANGUAGE plpgsql;

