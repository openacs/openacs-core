--
-- acs-messaging sql/upgrade-4.0-4.0.1a.sql
--
-- @author jmp@arsdigita.com
-- @creation-date 2000-11-03
-- @cvs-id $Id$
--

alter table acs_messages add (
    sent_date date
        constraint acs_messages_sent_date_nn
            not null
                disable,
    sender integer
        constraint acs_messages_sender_fk
            references parties (party_id)
                disable,
    rfc822_id varchar2(250)
        constraint acs_messages_rfc822_id_nn
            not null
                disable
        constraint acs_messages_rfc822_id_un
            unique
                disable
);

create table acs_mess_up (
    id integer primary key,
    sent_date date,
    sender integer,
    rfc822_id varchar2(250)
);

insert into acs_mess_up
    select m.message_id,
            r.publish_date as sent_date,
            o.creation_user as sender,
            (sysdate || '.' || message_id || '@'
             || utl_inaddr.get_host_name||'.hate') as rfc822_id
        from acs_objects o, cr_items i, cr_revisions r, acs_messages m
        where m.message_id = i.item_id
            and m.message_id = o.object_id
            and r.revision_id = i.live_revision;

update acs_messages
    set sent_date = (select sent_date from acs_mess_up where id = message_id),
        sender = (select sender from acs_mess_up where id = message_id),
        rfc822_id = (select rfc822_id from acs_mess_up where id = message_id);

drop table acs_mess_up;

alter table acs_messages modify constraint acs_messages_sent_date_nn enable;
alter table acs_messages modify constraint acs_messages_sender_fk enable;
alter table acs_messages modify constraint acs_messages_rfc822_id_nn enable;
alter table acs_messages modify constraint acs_messages_rfc822_id_un enable;

create or replace view acs_messages_all as
    select m.message_id, m.reply_to, m.sent_date, m.sender, m.rfc822_id,
           r.title, r.mime_type, r.content, o.context_id 
        from acs_objects o, cr_items i, cr_revisions r, acs_messages m
        where o.object_id = m.message_id and i.item_id = m.message_id
            and r.revision_id = i.live_revision;

create table acs_messages_outgoing (
    message_id integer
        constraint amo_message_id_fk
            references acs_messages (message_id) on delete cascade,
    recipient_id integer
        constraint amo_recipient_id_fk
            references parties (party_id),
    grouping_id integer,
    wait_until date not null,
    constraint acs_messages_outgoing_pk
        primary key (message_id, recipient_id)
);

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

create or replace package acs_message
as

    function new (
        message_id    in acs_messages.message_id%TYPE   default null,
        reply_to      in acs_messages.reply_to%TYPE     default null,
        sent_date     in acs_messages.sent_date%TYPE    default sysdate,
        sender        in acs_messages.sender%TYPE       default null,
        rfc822_id     in acs_messages.rfc822_id%TYPE    default null,
        title         in cr_revisions.title%TYPE        default null,
        mime_type     in cr_revisions.mime_type%TYPE    default 'text/plain',
        text          in varchar2                       default null,
        data          in cr_revisions.content%TYPE      default null,
        context_id    in acs_objects.context_id%TYPE,
        creation_date in acs_objects.creation_date%TYPE default sysdate,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip   in acs_objects.creation_ip%TYPE   default null,
        object_type   in acs_objects.object_type%TYPE   default 'acs_message'
    ) return acs_objects.object_id%TYPE;

    procedure delete (
        message_id    in acs_messages.message_id%TYPE
    );

    function message_p (
        message_id    in acs_messages.message_id%TYPE
    ) return char;

    procedure send (
        message_id    in acs_messages.message_id%TYPE,
        recipient_id  in parties.party_id%TYPE,
        grouping_id   in integer default NULL,
        wait_until    in date default SYSDATE
    );

end acs_message;
/
show errors

create or replace package body acs_message
as

    function new (
        message_id    in acs_messages.message_id%TYPE   default null,
        reply_to      in acs_messages.reply_to%TYPE     default null,
        sent_date     in acs_messages.sent_date%TYPE    default sysdate,
        sender        in acs_messages.sender%TYPE       default null,
        rfc822_id     in acs_messages.rfc822_id%TYPE    default null,
        title         in cr_revisions.title%TYPE        default null,
        mime_type     in cr_revisions.mime_type%TYPE    default 'text/plain',
        text          in varchar2                       default null,
        data          in cr_revisions.content%TYPE      default null,
        context_id    in acs_objects.context_id%TYPE,
        creation_date in acs_objects.creation_date%TYPE default sysdate,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip   in acs_objects.creation_ip%TYPE   default null,
        object_type   in acs_objects.object_type%TYPE   default 'acs_message'
    ) return acs_objects.object_id%TYPE
    is
        v_message_id acs_messages.message_id%TYPE;
        v_rfc822_id  acs_messages.rfc822_id%TYPE;
        v_name       cr_items.name%TYPE;
    begin
        if message_id is null then
            select acs_object_id_seq.nextval into v_message_id from dual;
        else
            v_message_id := message_id;
        end if;

        if rfc822_id is null then
            v_rfc822_id := sysdate || '.' || v_message_id || '@' ||
                utl_inaddr.get_host_name || '.hate';
        else
            v_rfc822_id := rfc822_id;
        end if;

        v_name := v_rfc822_id;

        v_message_id := content_item.new (
            name => v_name,
            parent_id => context_id,
            item_id => message_id,
            creation_date => creation_date,
            creation_user => creation_user,
            creation_ip => creation_ip,
            item_subtype => object_type,
            title => title,
            mime_type => mime_type,
            text => text,
            data => data,
            is_live => 't'
        );

        -- I hate you, milkman CR.
        -- Fix the broken permissions stuff content_item.new does
        update acs_objects set security_inherit_p = 't'
            where object_id = v_message_id;
        delete from acs_permissions where object_id = v_message_id;

        insert into
            acs_messages (message_id, reply_to, sent_date, sender, rfc822_id)
            values (v_message_id, reply_to, sent_date, sender, v_rfc822_id);

        return v_message_id;    
    end new;

    procedure delete (
        message_id in acs_messages.message_id%TYPE
    )
    is
    begin
        delete from acs_messages
            where message_id = acs_message.delete.message_id;
        content_item.delete(message_id);
    end;

    function message_p (
        message_id in acs_messages.message_id%TYPE
    ) return char
    is
        v_check_message_id char(1);
    begin
        select decode(count(message_id),0,'f','t') into v_check_message_id
            from acs_messages
            where message_id = message_p.message_id;
        return v_check_message_id;
    end message_p;

    procedure send (
        message_id    in acs_messages.message_id%TYPE,
        recipient_id  in parties.party_id%TYPE,
        grouping_id   in integer default NULL,
        wait_until    in date default SYSDATE
    )
    is
        v_wait_until date;
    begin
        v_wait_until := nvl(wait_until, SYSDATE);
        insert into acs_messages_outgoing
            (message_id, recipient_id, grouping_id, wait_until)
        values
            (message_id, recipient_id, grouping_id, nvl(wait_until,SYSDATE));
    end;

end acs_message;
/
show errors
