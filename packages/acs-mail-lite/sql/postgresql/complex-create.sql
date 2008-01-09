-- 
-- packages/acs-mail-lite/sql/postgresql/acs-mail-lite-complex-create.sql
-- 
-- @creation-date 2008-01-09
-- @arch-tag: e5c711fc-124f-4e7f-8276-ca393d743864
-- @cvs-id $Id$
--

CREATE TABLE acs_mail_lite_complex_queue (
    id                  	integer
                                constraint acs_mail_lite_complex_queue_pk
                                primary key,
    creation_date 		text,
    locking_server 		text,
    to_party_ids		text,
    cc_party_ids 		text,
    bcc_party_ids 		text,
    to_group_ids 		text,
    cc_group_ids 		text,
    bcc_group_ids 		text,
    to_addr 			text,
    cc_addr 			text,
    bcc_addr 			text,
    from_addr 			text,
    reply_to 			text,
    subject 			text,
    body 			text,
    package_id 			integer,
    files			text,
    file_ids 			text,
    folder_ids 			text,
    mime_type 			text,
    object_id 			integer,
    single_email_p 		boolean,
    no_callback_p		boolean,
    extraheaders 		text,
    alternative_part_p 		boolean,
    use_sender_p 		boolean
);
