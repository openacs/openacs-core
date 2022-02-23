--
-- since argument names change, we have to drop + recreate
--
DROP FUNCTION util__table_column_exists(text, text);

--
-- procedure util__table_column_exists/2
--
select define_function_args('util__table_column_exists','table_name,column');

CREATE OR REPLACE FUNCTION util__table_column_exists(
   p_table_name text,
   p_column text
) RETURNS boolean
AS $$
DECLARE
 v_schema    varchar;
 v_tablename varchar;
BEGIN
    IF (position('.' in p_table_name) = 0) THEN
        --
        -- table without a schema name
        --
        return exists (
            select 1 from information_schema.columns c
            where table_name  = lower(p_table_name)
            and column_name = lower(p_column));
    ELSE
        --
        -- table with schema name
        --
        SELECT split_part(p_table_name, '.', 1) into v_schema;
        SELECT split_part(p_table_name, '.', 2) into v_tablename;
        return exists (
            select 1 from information_schema.columns
            where p_table_name  = lower(v_tablename)
            and column_name = lower(p_column)
            and table_schema = v_schema);
    END IF;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION util__get_default(text, text);
select define_function_args('util__get_default','table_name,column');

CREATE OR REPLACE FUNCTION util__get_default(
   p_table_name text,
   p_column   text
) RETURNS information_schema.columns.column_default%TYPE
AS $$
BEGIN
      return (
        select column_default
          from information_schema.columns
         where table_name  = lower(p_table_name)
           and column_name = lower(p_column));
END;
$$ LANGUAGE plpgsql;

--
-- procedure util__get_primary_keys/1
--
select define_function_args('util__get_primary_keys','table_name');



--
-- procedure util__foreign_key_exists/4
--
DROP FUNCTION util__foreign_key_exists(text,text,text,text);
select define_function_args('util__foreign_key_exists','table_name,column,reftable,refcolumn');

CREATE OR REPLACE FUNCTION util__foreign_key_exists(
   p_table_name text,
   p_column text,
   p_reftable text,
   p_refcolumn text
) RETURNS boolean
AS $$
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
        and tc.table_name   = lower(p_table_name)
        and kcu.column_name = lower(p_column)
        and ccu.table_name  = lower(p_reftable)
        and ccu.column_name = lower(p_refcolumn));
END;
$$ LANGUAGE plpgsql;




--
-- procedure util__not_null_exists/2
--
DROP FUNCTION util__not_null_exists(text,text);

select define_function_args('util__not_null_exists','table_name,column');

CREATE OR REPLACE FUNCTION util__not_null_exists(
   p_table_name text,
   p_column   text
) RETURNS boolean
AS $$
DECLARE
BEGIN
      return (
        coalesce((
        select is_nullable = 'NO'
          from information_schema.columns
         where table_name  = lower(p_table_name)
           and column_name = lower(p_column)), false));
END;
$$ LANGUAGE plpgsql;



--
-- procedure primary_key_exists/3
--
DROP FUNCTION util__primary_key_exists(text,text,boolean);
select define_function_args('util__primary_key_exists','table_name,column,single_p;true');

CREATE OR REPLACE FUNCTION util__primary_key_exists(
   p_table_name text,
   p_column     text,
   p_single_p   boolean default true
) RETURNS boolean
AS $$
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
        and tc.table_name   = lower(p_table_name)
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
