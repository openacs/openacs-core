--
-- procedure util__table_exists/1
--
CREATE OR REPLACE FUNCTION util__table_exists(
   name text
) RETURNS boolean AS $$
DECLARE
 v_schema    varchar;
 v_tablename varchar;
BEGIN
    IF (position('.' in name) = 0) THEN
	--
	-- table without a schema name
	--
	return exists (
	    select 1 from pg_class
		where relname = name
	    and pg_table_is_visible(oid));
    ELSE
	--
	-- table with schema name
	--
	SELECT split_part(name, '.', 1) into v_schema;
	SELECT split_part(name, '.', 2) into v_tablename;
	return exists (
	    select 1 from information_schema.tables
	    where table_schema = v_schema
	    and   table_name = v_tablename);
   END IF;
END;
$$ LANGUAGE plpgsql;

--
-- procedure util__table_column_exists/1
--
CREATE OR REPLACE FUNCTION util__table_column_exists(
   p_table  text,
   p_column text
) RETURNS boolean AS $$
DECLARE
 v_schema    varchar;
 v_tablename varchar;
BEGIN
    IF (position('.' in p_table) = 0) THEN
	--
	-- table without a schema name
	--
	return exists (
	    select 1 from information_schema.columns c
	    where table_name  = lower(p_table)
	    and column_name = lower(p_column));
    ELSE
	--
	-- table with schema name
	--
	SELECT split_part(p_table, '.', 1) into v_schema;
	SELECT split_part(p_table, '.', 2) into v_tablename;
	return exists (
	    select 1 from information_schema.columns
	    where table_name  = lower(v_tablename)
	    and column_name = lower(p_column)
	    and table_schema = v_schema);
    END IF;
END;
$$ LANGUAGE plpgsql;


--
-- procedure util__view_exists/1
--
CREATE OR REPLACE FUNCTION util__view_exists(
   name text
) RETURNS boolean AS $$
DECLARE
 v_schema    varchar;
 v_tablename varchar;
BEGIN
    IF (position('.' in name) = 0) THEN
	--
	-- view without a schema name
	--
	return exists (
	   select 1 from pg_views where viewname = name);
    ELSE
	--
	-- table with schema name
	--
	SELECT split_part(name, '.', 1) into v_schema;
	SELECT split_part(name, '.', 2) into v_tablename;
	return exists (
	    select 1 from information_schema.views
	    where table_name  = lower(v_tablename)
	    and table_schema = v_schema);
    END IF;
END;
$$ LANGUAGE plpgsql;
