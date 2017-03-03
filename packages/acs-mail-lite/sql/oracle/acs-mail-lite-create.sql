--
-- A simple mail queue
--
-- @author <a href="mailto:eric@openforce.net">eric@openforce.net</a>
-- @version $Id$
--

create sequence acs_mail_lite_id_seq;

CREATE TABLE acs_mail_lite_queue (
    message_id                integer
                              constraint acs_mail_lite_queue_pk 
                              PRIMARY KEY,
    creation_date             varchar(4000),
    locking_server            varchar(4000),
    to_addr                   varchar(4000),
    cc_addr                   clob,
    bcc_addr                  clob,
    from_addr                 varchar(400),
    reply_to                  varchar(400),
    subject                   varchar(4000),
    body                      clob,
    package_id                integer
                              constraint amlq_package_id_fk
                              references apm_packages,
    file_ids                  varchar(4000),
    filesystem_files          varchar(4000),
    delete_filesystem_files_p char(1)
                              constraint amlq_del_fs_files_p_ck
                              check (delete_filesystem_files_p in ('t','f')),
    mime_type                 varchar(200),
    object_id                 integer,
    no_callback_p             char(1)
                              constraint amlq_no_callback_p_ck
                              check (no_callback_p in ('t','f')),
    extraheaders              clob,
    use_sender_p              char(1)
                              constraint amlq_use_sender_p_ck
                              check (use_sender_p in ('t','f'))
);

create table acs_mail_lite_mail_log (
    party_id                    integer
                                constraint acmlml_party_id_fk
                                references parties (party_id)
                                on delete cascade
				constraint acs_mail_lite_log_pk
				primary key,
    last_mail_date		date default sysdate
);


create table acs_mail_lite_bounce (
    party_id                     integer
                                constraint acmlb_party_id_fk
                                references parties (party_id)
                                on delete cascade
				constraint acs_mail_lite_bou_pk
				primary key,
    bounce_count		integer default 1
);


create table acs_mail_lite_bounce_notif (
    party_id                    integer
				constraint amlbn_party_id_fk
                                references parties (party_id)
                                on delete cascade
				constraint acs_mail_lite_notif_pk
				primary key,
    notification_time		date default sysdate,
    notification_count		integer default 0
);

