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

-- Make sure sync_time is not null for the first message imported. If we don't
-- do this we are missing a set of base messages to merge against on the next 
-- catalog import.
-- Messages with only one revision

-- Messages with only one revision
-- This query is slow. Not sure how to speed it up.
update lang_messages 
       set sync_time = current_timestamp
       where not exists (select 1
                               from lang_messages_audit lma
                               where lma.package_key = lang_messages.package_key
                                 and lma.message_key = lang_messages.message_key
                                 and lma.locale = lang_messages.locale
                              );

-- Messages with multiple revisions
-- This query is slow as well.
 update lang_messages_audit 
        set sync_time = current_timestamp
        where overwrite_date = (select max(lma2.overwrite_date)
                                    from lang_messages_audit lma2
                                    where lma2.package_key = lang_messages_audit.package_key
                                      and lma2.message_key = lang_messages_audit.message_key
                                      and lma2.locale      = lang_messages_audit.locale
                                    );
