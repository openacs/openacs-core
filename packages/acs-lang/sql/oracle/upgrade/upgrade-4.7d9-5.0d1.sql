--
-- Oracle upgrade script from 4.7d9 to 5.0d1
--
-- 1. Adds an enabled_p flag to ad_locales.
-- 
-- 2. Adds a comment field to lang_messages_audit
--
-- 3. Renames the lang_messages_audit.message column to 'old_message' in order to make the meaning more clear.
--
-- 4. Adds a description column to lang_message_keys.
--
-- @author Simon Carstensen (simon@collaboraid.biz)
-- @author Lars Pind (lars@collaboraid.biz)
--
-- @creation-date 2003-08-11
-- @cvs-id $Id$
--


-- 1. Adds an enabled_p flag to ad_locales.

-- New enabled_p column in ad_locales
alter table ad_locales
  add   enabled_p char(1) default 't'
        constraint ad_locale_enp_tf check(enabled_p in ('t','f'));

-- Let all locales be enabled for sites that are upgrading
update ad_locales set enabled_p = 't';

-- New view
create or replace view enabled_locales as
select * from ad_locales
where enabled_p = 't';




-- 2. Adds a comment field to lang_messages_audit

-- Add a comment field to the message audit table
alter table lang_messages_audit add comment_text clob;
commit;




-- 3. Renames the lang_messages_audit.message column to 'old_message' in order to make the meaning more clear.

-- Rename the coclumn 'message' to 'old_message' in the lang_messages_audit table
alter table lang_messages_audit add old_message clob;
update lang_messages_audit set old_message = message;
commit;
alter table lang_messages_audit drop (message);


-- 4. Adds a description column to lang_message_keys.

alter table lang_message_keys add description clob;
