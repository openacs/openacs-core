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
