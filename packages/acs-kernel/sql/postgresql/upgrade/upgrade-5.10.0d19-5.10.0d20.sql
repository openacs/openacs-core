--
-- procedure acs_object__set_attribute/3
--
CREATE OR REPLACE FUNCTION acs_object__set_attribute(
   object_id_in integer,
   attribute_name_in varchar,
   value_in varchar
) RETURNS integer AS $$
DECLARE
  v_table_name           varchar;  
  v_column               varchar;  
  v_key_sql              text; 
  v_return               text; 
  v_storage              text;
BEGIN

   v_storage    := acs_object__get_attribute_storage(object_id_in, attribute_name_in);
   v_column     := acs_object__get_attr_storage_column(v_storage);
   v_table_name := acs_object__get_attr_storage_table(v_storage);
   v_key_sql    := acs_object__get_attr_storage_sql(v_storage);

   if value_in is null then
      execute 'update ' || v_table_name || ' set ' || v_column || ' = NULL where ' || v_key_sql;   
   else
      execute 'update ' || v_table_name || ' set ' || quote_ident(v_column) || ' = ' || quote_literal(value_in) || ' where ' || v_key_sql;
   end if;
   
   return 0; 
END;
$$ LANGUAGE plpgsql;
