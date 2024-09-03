
alter table lang_message_keys add column if not exists object_id integer
       constraint lang_message_keys_object_id_fk
       references acs_objects(object_id) on delete cascade;
