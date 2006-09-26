--
-- packages/acs-messaging/sql/acs-messaging-create.sql
--
-- @author John Prevost <jmp@arsdigita.com>
-- @creation-date 2000-08-27
-- @cvs-id $Id$
--

set feedback off

-- Object System Metadata ----------------------------------------------

begin

    acs_object_type.create_type (
        supertype => 'content_item',
        object_type => 'acs_message',
        pretty_name => 'Message',
        pretty_plural => 'Messages',
        table_name => 'acs_messages',
        id_column => 'message_id',
        name_method => 'acs_message.name'
    );

    acs_object_type.create_type (
        supertype => 'content_revision',
        object_type => 'acs_message_revision',
        pretty_name => 'Message Revision',
        pretty_plural => 'Message Revisions',
        name_method => 'acs_object.default_name'
    );

end;
/
show errors

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
    sent_date date
        constraint acs_messages_sent_date_nn
            not null,
    sender integer
        constraint acs_messages_sender_fk
            references parties (party_id),
    rfc822_id varchar2(250)
        constraint acs_messages_rfc822_id_nn
            not null
        constraint acs_messages_rfc822_id_un
            unique
);

create index acs_messages_reply_to_idx on acs_messages (reply_to);
create index acs_messages_sender_idx on acs_messages (sender);

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

create table acs_messages_outgoing (
    message_id integer
        constraint amo_message_id_fk
            references acs_messages (message_id) on delete cascade,
    to_address varchar2(1000)
        constraint amo_to_address_nn
            not null,
    grouping_id integer,
    wait_until date
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

@@ acs-messaging-views
@@ acs-messaging-packages

set feedback on
