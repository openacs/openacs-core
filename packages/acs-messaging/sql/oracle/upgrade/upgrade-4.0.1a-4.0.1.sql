--
-- acs-messaging sql/upgrade-4.0.1a-4.0.1.sql
--
-- @author jmp@arsdigita.com
-- @creation-date 2000-11-15
-- @cvs-id $Id$
--

begin
    acs_object_type.create_type (
        supertype => 'content_revision',
        object_type => 'acs_message_revision',
        pretty_name => 'Message Revision',
        pretty_plural => 'Message Revisions',
        table_name => 'CR_REVISIONS',
        id_column => 'REVISION_ID',
        name_method => 'ACS_OBJECT.DEFAULT_NAME'
    );
end;
/
show errors

alter table acs_messages_outgoing add (
    to_address varchar2(1000)
        constraint amo_to_address_nn
            not null
                disable
);

update acs_messages_outgoing
    set to_address = (select email from parties where party_id = recipient_id);

alter table acs_messages_outgoing
    drop constraint acs_messages_outgoing_pk;

alter table acs_messages_outgoing
    add constraint acs_messages_outgoing_pk
        primary key (message_id, to_address);

alter table acs_messages_outgoing
    modify constraint amo_to_address_nn enable;

alter table acs_messages_outgoing
    drop column recipient_id;

@@ acs-messaging-views
@@ acs-messaging-packages

set feedback on
