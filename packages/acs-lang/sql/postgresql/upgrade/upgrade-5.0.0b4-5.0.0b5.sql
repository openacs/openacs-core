-- Datamodel changes in message-catalog.sql related to the new message catalog upgrade support.
-- See Tcl proc lang::catalog::import_messages.
--
-- @author Peter Marklund

-- The lang_messages_keys.upgrade_status column carry any information over the corresponding
-- en_US row in the lang_messages table and were not being kept in sync.
alter table lang_message_keys drop column upgrade_status;

-- Add new columns to the lang_messages table 
alter table lang_messages add deleted_p boolean;
alter table lang_messages alter column deleted_p set default 'f';
alter table lang_messages add sync_time timestamptz;
alter table lang_messages add conflict_p boolean;
alter table lang_messages alter column conflict_p set default 'f';
update lang_messages set deleted_p = 'f', conflict_p = 'f';

-- Add new columns to the lang_messages_audit tables
alter table lang_messages_audit add deleted_p boolean;
alter table lang_messages_audit alter column deleted_p set default 'f';
alter table lang_messages_audit add sync_time timestamptz;
alter table lang_messages_audit add conflict_p boolean;
alter table lang_messages_audit alter column conflict_p set default 'f';
alter table lang_messages_audit add    upgrade_status     varchar(30)
                                       constraint lang_messages_us_ck
                                       check (upgrade_status in ('no_upgrade', 'added', 'deleted', 'updated'));
update lang_messages_audit set deleted_p = 'f', conflict_p = 'f', upgrade_status = 'no_upgrade';
