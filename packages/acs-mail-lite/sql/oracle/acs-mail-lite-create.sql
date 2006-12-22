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
    to_addr                     varchar(400),
    from_addr                   varchar(200),
    subject                     varchar(200),
    body                        clob,
    extra_headers               clob,
    bcc                         clob,
    package_id			integer
    				constraint acs_mail_lite_queue_pck_fk
				references apm_packages,
    valid_email_p		varchar2(1)
				constraint acs_mail_lite_qu_valid_em_p_ck
				check (valid_email_p in ('t','f'))
);

create table acs_mail_lite_mail_log (
    party_id                    integer
                                constraint acs_mail_lite_log_user_id_fk
                                references parties (party_id)
                                on delete cascade
				constraint acs_mail_lite_log_pk
				primary key,
    last_mail_date		date default sysdate
);


create table acs_mail_lite_bounce (
    party_id                     integer
                                constraint acs_mail_lite_bou_user_id_fk
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
				constraint acs_mail_lite_notif_pk
				primary key,
    notification_time		date default sysdate,
    notification_count		integer default 0
);


CREATE TABLE acs_mail_lite_complex_queue (
    id 				integer
                                constraint acs_mail_lite_complex_queue_pk 
				PRIMARY KEY,
    creation_date 		text,
    locking_server 		text,
    to_party_ids 		varchar(4000),
    cc_party_ids 		varchar(4000),
    bcc_party_ids 		varchar(4000),
    to_group_ids 		varchar(4000),
    cc_group_ids		varchar(4000),
    bcc_group_ids 		varchar(4000),
    to_addr 			clob,
    cc_addr 			clob,
    bcc_addr			clob,
    from_addr 			varchar(400),
    reply_to 			varchar(400),
    subject 			varchar(4000),
    body 			clob,
    package_id 			integer,
    files 			varchar(4000),
    file_ids 			varchar(4000),
    folder_ids 			varchar(4000),
    mime_type 			varchar(200),
    object_id 			integer,
    single_email_p 		varchar2(1)
				constraint acs_mail_lite_co_qu_single_em_p_ck
				check (valid_email_p in ('t','f')),
    no_callback_p 		varchar2(1)
				constraint acs_mail_lite_co_qu_no_callb_p_ck
				check (valid_email_p in ('t','f')),
    extraheaders 		clob,
    alternative_part_p		varchar2(1)
				constraint acs_mail_lite_co_qu_alt_part_p_ck
				check (valid_email_p in ('t','f')),
    use_sender_p 		varchar2(1)
				constraint acs_mail_lite_co_qu_use_sender_p_ck
				check (valid_email_p in ('t','f'))
);
