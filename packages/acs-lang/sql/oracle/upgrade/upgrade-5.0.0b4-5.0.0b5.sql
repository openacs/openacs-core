-- Datamodel changes in message-catalog.sql related to the new message catalog upgrade support.
-- See Tcl proc lang::catalog::import_messages.
--
-- @author Peter Marklund

-- Changes to lang_message_keys table
-- Column not needed as en_US row in lang_messages table has same info
alter table lang_message_keys drop column upgrade_status;

-- Add new columns to the lang_messages table 
alter table lang_messages add deleted_p char(1) default 'f'
                              constraint lang_messages_dp_ck check (deleted_p in ('t','f'));
alter table lang_messages add sync_time date;
alter table lang_messages add conflict_p  char(1) default 'f'
                              constraint lang_messages_cp_ck check (conflict_p in ('t','f'));
update lang_messages set deleted_p = 'f', conflict_p = 'f';

-- Add new columns to the lang_messages_audit tables
alter table lang_messages_audit add deleted_p char(1) default 'f'
                              constraint lang_messages_audit_dp_ck check (deleted_p in ('t','f'));
alter table lang_messages_audit add sync_time date;
alter table lang_messages_audit add conflict_p  char(1) default 'f'
                              constraint lang_messages_audit_cp_ck check (conflict_p in ('t','f'));
alter table lang_messages_audit add upgrade_status     varchar2(30)
                              constraint lang_messages_audit_us_ck
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
update lang_messages lm
       set lm.sync_time = sysdate
       where not exists (select 1
                               from lang_messages_audit lma
                               where lma.package_key = lm.package_key
                                 and lma.message_key = lm.message_key
                                 and lma.locale = lm.locale
                              );

-- Messages with multiple revisions
-- This query is slow as well.
 update lang_messages_audit lma1
        set lma1.sync_time = sysdate
        where lma1.overwrite_date = (select min(lma2.overwrite_date)
                                    from lang_messages_audit lma2
                                    where lma2.package_key = lma1.package_key
                                      and lma2.message_key = lma1.message_key
                                      and lma2.locale      = lma1.locale
                                    );
