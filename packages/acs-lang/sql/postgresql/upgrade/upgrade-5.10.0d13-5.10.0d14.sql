
-- Populate the newly created object_id column with the group_ids from
-- message keys that have been automatically generated
update lang_message_keys set
  object_id = cast(split_part(message_key, '_', 3) as integer)
 where package_key = 'acs-translations'
   and message_key like 'group_title_%'
   and exists (select 1 from acs_objects where object_id = cast(split_part(message_key, '_', 3) as integer));
