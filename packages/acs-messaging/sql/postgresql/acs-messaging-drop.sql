--
-- packages/acs-messaging/sql/acs-messaging-drop.sql
--
-- @author akk@arsdigita.com
-- @creation-date 2000-08-31
-- @cvs-id $Id$
--

-- drop functions
drop trigger acs_message_insert_tr on acs_messages;
drop trigger acs_message_update_tr on acs_messages;
drop function acs_message_insert_tr();
drop function acs_message_update_tr();

drop function acs_message__edit (integer,varchar,varchar,varchar,
                                 text,integer,timestamptz,integer,varchar,boolean);
drop function acs_message__new (integer,integer,timestamptz,integer,
                                varchar,varchar,varchar,varchar,varchar,text,
                                integer,integer,integer,varchar,varchar,boolean);
drop function acs_message__new (integer,integer,timestamptz,integer,
                                varchar,varchar,varchar,varchar,varchar,text,
                                integer,integer,integer,varchar,varchar,boolean,integer);
drop function acs_message__delete (integer);
drop function acs_message__message_p (integer);
drop function acs_message__send (integer,varchar,integer,timestamptz);
drop function acs_message__send (integer,integer,integer,timestamptz);
drop function acs_message__first_ancestor (integer);
drop function acs_message__new_file (integer,integer,varchar,varchar,
                                     text,varchar,text,timestamptz,integer,
                                     varchar,boolean);
drop function acs_message__new_file (integer,integer,varchar,varchar,
                                     text,varchar,text,timestamptz,integer,
                                     varchar,boolean,integer);
drop function acs_message__edit_file (integer,varchar,text,varchar,
                                      text,timestamptz,integer,varchar,boolean);
drop function acs_message__delete_file (integer);
drop function acs_message__new_image (integer,integer,varchar,varchar,
                                      text,varchar,text,integer,integer,
                                      timestamptz,integer,varchar,boolean);
drop function acs_message__new_image (integer,integer,varchar,varchar,
                                      text,varchar,text,integer,integer,
                                      timestamptz,integer,varchar,boolean,integer);
drop function acs_message__edit_image (integer,varchar,text,varchar,
                                       text,integer,integer,timestamptz,integer,
                                       varchar,boolean);
drop function acs_message__delete_image (integer);
drop function acs_message__new_extlink (varchar,integer,varchar,varchar,text,
                                        integer,timestamptz,integer,varchar);
drop function acs_message__new_extlink (varchar,integer,varchar,varchar,text,
                                        integer,timestamptz,integer,varchar,integer);
drop function acs_message__edit_extlink (integer,varchar,varchar,text);
drop function acs_message__delete_extlink (integer);
drop function acs_message__name (integer);

-- drop views
drop view acs_messages_all;
drop view acs_messages_latest;

-- drop indices
drop index acs_messages_reply_to_idx;
drop index acs_messages_sender_idx;

-- drop tables
drop table acs_messages_outgoing;
drop table acs_messages;

-- drop acs_object_types
select acs_object_type__drop_type('acs_message_revision', 't');
select acs_object_type__drop_type('acs_message', 't');


--drop package acs_message;

--drop table acs_messages_outgoing;

--drop view acs_messages_all;

--drop table acs_messages;

