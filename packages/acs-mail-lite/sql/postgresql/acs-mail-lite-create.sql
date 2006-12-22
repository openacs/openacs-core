--
-- A simple mail queue
--
-- @author <a href="mailto:eric@openforce.net">eric@openforce.net</a>
-- @version $Id$
--

create sequence acs_mail_lite_id_seq;

create table acs_mail_lite_queue (
    message_id                  integer
                                constraint acs_mail_lite_queue_pk
                                primary key,
    to_addr                     text,
    from_addr                   varchar(200),
    subject                     varchar(200),
    body                        text,
    extra_headers               text,
    bcc                         text,
    package_id			integer
    				constraint acs_mail_lite_queue_pck_fk
				references apm_packages,
    valid_email_p		boolean
);

create table acs_mail_lite_mail_log (
    party_id                     integer
                                constraint acs_mail_lite_log_party_id_fk
                                references parties (party_id)
                                on delete cascade
				constraint acs_mail_lite_log_pk
				primary key,
    last_mail_date		timestamptz default current_timestamp
);


create table acs_mail_lite_bounce (
    party_id                     integer
                                constraint acs_mail_lite_bou_party_id_fk
                                references parties (party_id)
                                on delete cascade
				constraint acs_mail_lite_bou_pk
				primary key,
    bounce_count		integer default 1
);


create table acs_mail_lite_bounce_notif (
    party_id                    integer
				constraint acs_mail_li_bou_notif_us_id_fk
                                references parties (party_id)
                                on delete cascade
				constraint acs_mail_lite_bounce_notif_pk
				primary key,
    notification_time		timestamptz default current_timestamp,
    notification_count		integer default 0
);


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
