-- Datamodel changes in message-catalog.sql related to the new message catalog upgrade support.
-- See Tcl proc lang::catalog::import_messages.
--
-- @author Peter Marklund

-- Changes to lang_message_keys table
-- Column not needed as en_US row in lang_messages table has same info
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

-- Missing this primary key made some queries below very slow
alter table lang_messages_audit add constraint lang_messages_audit_pk primary key (package_key, message_key, locale, overwrite_date);

-- We have to leave sync_time null since we don't know when the messages in the db were last in sync
-- with the catalog files
