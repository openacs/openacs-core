--
-- packages/acs-messaging/sql/acs-messaging-create.sql
--
-- @author John Prevost <jmp@arsdigita.com>
-- @author Jon Griffin <jon@jongriffin.com>
-- @creation-date 2000-08-27
--
-- @cvs-id $Id$
--  updated for OpenACS

-- Object System Metadata ----------------------------------------------

select acs_object_type__create_type (
    'acs_message',
    'Message',
    'Messages',
    'content_item',
    'acs_messages',
    'message_id',
    null,
    'f',
    null,
    'acs_message__name'
);

select acs_object_type__create_type (
    'acs_message_revision',
    'Message Revision',
    'Message Revisions',
    'content_revision',
    null,
    null,
    null,
    'f',
    null,
    'acs_object__default_name'
);


-- Raw Tables and Comments ---------------------------------------------

create table acs_messages (     -- extends cr_items
    message_id integer
        constraint acs_messages_message_id_fk
            references cr_items (item_id) on delete cascade
        constraint acs_messages_message_id_pk
            primary key,
    -- we will need to find a way to make reply_to go to 0 instead of null
    -- to improve scalability
    reply_to integer
        constraint acs_messages_reply_to_fk
            references acs_messages (message_id) on delete set null,

    sent_date timestamptz
        constraint acs_messages_sent_date_nn
            not null,
    sender integer
        constraint acs_messages_sender_fk
            references parties (party_id),
    rfc822_id varchar(250)
        constraint acs_messages_rfc822_id_nn
            not null
        constraint acs_messages_rfc822_id_un
            unique,
    tree_sortkey varbit
);

create index acs_messages_tree_skey_idx on acs_messages (tree_sortkey);
create index acs_messages_reply_to_idx on acs_messages (reply_to);
create index acs_messages_sender_idx on acs_messages (sender);
create index acs_messages_sent_idx on acs_messages (sent_date);

comment on table acs_messages is '
    A generic message which may be attached to any object in the system.
';

comment on column acs_messages.reply_to is '
    Pointer to a message this message contains a reply to, for threading.
';

comment on column acs_messages.sent_date is '
    The date the message was sent (may be distinct from when it was created
    or published in the system.)
';

comment on column acs_messages.sender is '
    The person who sent the message (may be distinct from the person who
    entered the message in the system.)
';

comment on column acs_messages.rfc822_id is '
    The RFC822 message-id of this message, for sending email.
';


-- support for tree queries on acs_messages

create or replace function acs_message_get_tree_sortkey(integer) returns varbit as '
declare
  p_message_id    alias for $1;
begin
  return tree_sortkey from acs_messages where message_id = p_message_id;
end;' language 'plpgsql' stable strict;

create or replace function acs_message_insert_tr () returns opaque as '
declare
        v_parent_sk     varbit  default null;
        v_max_value     integer;
begin
	if new.reply_to is null then
	    select max(tree_leaf_key_to_int(tree_sortkey)) into v_max_value
              from acs_messages
             where reply_to is null;
        else
	    select max(tree_leaf_key_to_int(tree_sortkey)) into v_max_value
              from acs_messages
             where reply_to = new.reply_to;

            select tree_sortkey into v_parent_sk 
              from acs_messages
             where message_id = new.reply_to;
        end if;

        new.tree_sortkey := tree_next_key(v_parent_sk, v_max_value);

        return new;

end;' language 'plpgsql';

create trigger acs_message_insert_tr before insert 
on acs_messages 
for each row 
execute procedure acs_message_insert_tr ();

create function acs_message_update_tr () returns opaque as '
declare
        v_parent_sk     varbit default null;
        v_max_value     integer;
        v_rec           record;
        clr_keys_p      boolean default ''t'';
begin
        if new.message_id = old.message_id and 
           ((new.reply_to = old.reply_to) or 
            (new.reply_to is null and old.reply_to is null)) then

           return new;

        end if;

        for v_rec in select message_id, reply_to
                     from acs_messages
                     where tree_sortkey between new.tree_sortkey and tree_right(new.tree_sortkey)
                     order by tree_sortkey
        LOOP
            if clr_keys_p then
               update acs_messages set tree_sortkey = null
               where tree_sortkey between new.tree_sortkey and tree_right(new.tree_sortkey);
               clr_keys_p := ''f'';
            end if;
            
            select max(tree_leaf_key_to_int(tree_sortkey)) into v_max_value
              from acs_messages
              where reply_to = v_rec.reply_to;

            select tree_sortkey into v_parent_sk 
              from acs_messages 
             where message_id = v_rec.reply_to;

            update acs_messages
               set tree_sortkey = tree_next_key(v_parent_sk, v_max_value)
             where message_id = v_rec.message_id;

        end LOOP;

        return new;

end;' language 'plpgsql';

create trigger acs_message_update_tr after update 
on acs_messages
for each row 
execute procedure acs_message_update_tr ();


create table acs_messages_outgoing (
    message_id integer
        constraint amo_message_id_fk
            references acs_messages (message_id) on delete cascade,
    to_address varchar(1000)
        constraint amo_to_address_nn
            not null,
    grouping_id integer,
    wait_until timestamptz
        constraint amo_wait_until_nn not null,
    constraint acs_messages_outgoing_pk
        primary key (message_id, to_address)
);

comment on table acs_messages_outgoing is '
    Set of messages to be sent to parties.  It is assumed that sending a
    message either queues it in a real MTA or fails, so no information about
    what''s been tried how many times is kept.
';

comment on column acs_messages_outgoing.to_address is '
    The email address to send this message to.  Note that this will
    probably become a party_id again once upgrading a party to a user
    is possible.
';

comment on column acs_messages_outgoing.grouping_id is '
    This identifier is used to group sets of messages to be sent as
    digests.  When a message is about to be sent, any other messages
    with the same grouping_id will be put together with it in a
    digest.  It is recommended but not required that an object id is
    used.  Bboard, for example, might use the forum id that the user''s
    subscribed to.  For instant (non-digest) updates, it would be
    appropriate to use null, which is never equal to anything else.
';

comment on column acs_messages_outgoing.wait_until is '
    Don''t schedule a send until after this date.  If another message with
    the same grouping ID is scheduled to be sent, then this message may be
    sent at the same time.  (So, for example, daily digests would be
    achieved by setting the grouping_id to the same value, and the wait_until
    value to the end of the current day.  As soon as one message in the group
    is to be sent, all will be sent.)
';

\i acs-messaging-views.sql
\i acs-messaging-packages.sql

