-- Oracle version of 
--    alter table add column ... if exists ... 
--
DECLARE
  v_col_exists NUMBER;
BEGIN
  SELECT count(*) INTO v_col_exists
    FROM user_tab_cols
    WHERE column_name = 'OBJECT_ID'
      AND table_name = 'LANG_MESSAGE_KEYS';

   IF (v_col_exists = 0) THEN
      EXECUTE IMMEDIATE 'alter table lang_message_keys add object_id integer
       constraint lang_message_keys_object_id_fk
       references acs_objects(object_id) on delete cascade';
  END IF;
END;
/

