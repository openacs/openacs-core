--
-- packages/acs-messaging/sql/acs-messaging-create.sql
--
-- @author John Prevost <jmp@arsdigita.com>
-- @author Jon Griffin <jon@jongriffin.com>
--
-- @creation-date 2000-11-15
-- @cvs-id $Id$
--
-- Updated by Jon Griffin for OpenACS

create view acs_messages_all as
    select m.message_id, m.reply_to, m.sent_date, m.sender, m.rfc822_id,
           m.tree_sortkey, r.revision_id, r.title, r.mime_type, r.content
        from cr_items i, cr_revisions r, acs_messages m
        where i.item_id = m.message_id and r.revision_id = i.live_revision;

create view acs_messages_latest as
    select m.message_id, m.reply_to, m.sent_date, m.sender, m.rfc822_id,
           m.tree_sortkey, r.revision_id, r.title, r.mime_type, r.content
        from cr_items i, cr_revisions r, acs_messages m
        where i.item_id = m.message_id
            and r.revision_id = content_item__get_latest_revision(i.item_id);

