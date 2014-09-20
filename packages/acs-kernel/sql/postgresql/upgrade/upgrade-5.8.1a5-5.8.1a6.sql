
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
