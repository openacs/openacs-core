--
-- Create acs_mail_lite_complex_queue
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

-- Make sure that emails are going to parties not to users and 
-- therefore logging is for parties, not for users.

alter table acs_mail_lite_mail_log add column party_id integer constraint amlml_party_id_fk references parties(party_id) on delete cascade;
update acs_mail_lite_mail_log set party_id = user_id;
alter table acs_mail_lite_mail_log drop column user_id;

alter table acs_mail_lite_bounce add column party_id integer constraint amlb_party_id_fk references parties(party_id) on delete cascade;
update acs_mail_lite_bounce set party_id = user_id;
alter table acs_mail_lite_bounce drop column user_id;

alter table acs_mail_lite_bounce_notif drop constraint acs_mail_li_bou_notif_us_id_fk;
alter table acs_mail_lite_bounce_notif add column party_id integer constraint amlbn_party_id_fk references parties(party_id) on delete cascade;
update acs_mail_lite_bounce_notif set party_id = user_id;
alter table acs_mail_lite_bounce_notif drop column user_id;
