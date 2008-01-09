--
-- Create acs_mail_lite_complex_queue; 
--

CREATE TABLE acs_mail_lite_complex_queue (
    id              integer
                    constraint acs_mail_lite_complex_queue_pk 
                    PRIMARY KEY,
    creation_date       varchar(4000),
    locking_server      varchar(4000),
    to_party_ids        varchar(4000),
    cc_party_ids        varchar(4000),
    bcc_party_ids       varchar(4000),
    to_group_ids        varchar(4000),
    cc_group_ids        varchar(4000),
    bcc_group_ids       varchar(4000),
    to_addr             clob,
    cc_addr             clob,
    bcc_addr            clob,
    from_addr           varchar(400),
    reply_to            varchar(400),
    subject             varchar(4000),
    body            clob,
    package_id          integer,
    files           varchar(4000),
    file_ids            varchar(4000),
    folder_ids          varchar(4000),
    mime_type           varchar(200),
    object_id           integer,
    single_email_p      varchar2(1)
                constraint aml_co_qu_single_em_p_ck
                check (single_email_p in ('t','f')),
    no_callback_p       varchar2(1)
                constraint aml_co_qu_no_callb_p_ck
                check (no_callback_p in ('t','f')),
    extraheaders        clob,
    alternative_part_p      varchar2(1)
                constraint aml_co_qu_alt_part_p_ck
                check (alternative_part_p in ('t','f')),
    use_sender_p        varchar2(1)
                constraint aml_co_qu_use_sender_p_ck
                check (use_sender_p in ('t','f'))
);

-- Make sure that emails are going to parties not to users and 
-- therefore logging is for parties, not for users.
alter table acs_mail_lite_mail_log add party_id integer constraint amlml_party_id_fk references parties(party_id) on delete cascade;
update acs_mail_lite_mail_log set party_id = user_id;
alter table acs_mail_lite_mail_log drop column user_id;

alter table acs_mail_lite_bounce add party_id integer constraint amlb_party_id_fk references parties(party_id) on delete cascade;
update acs_mail_lite_bounce set party_id = user_id;
alter table acs_mail_lite_bounce drop column user_id;

alter table acs_mail_lite_bounce_notif drop constraint acs_mail_li_bou_notif_us_id_fk;
alter table acs_mail_lite_bounce_notif add party_id integer constraint amlbn_party_id_fk references parties (party_id) on delete cascade;
update acs_mail_lite_bounce_notif set party_id = user_id;
alter table acs_mail_lite_bounce_notif drop column user_id;

