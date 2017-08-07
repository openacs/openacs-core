
begin;

-- added
select define_function_args('util__get_primary_keys','table');

--
-- procedure util__get_primary_keys/1
--
CREATE OR REPLACE FUNCTION util__get_primary_keys(
   p_table text
) RETURNS SETOF pg_attribute.attname%TYPE AS $$
  SELECT a.attname
    FROM pg_index i
    JOIN pg_attribute a ON a.attrelid = i.indrelid
                       AND a.attnum = ANY(i.indkey)
  WHERE i.indrelid = p_table::regclass
    AND i.indisprimary;
$$ LANGUAGE sql;

end;
