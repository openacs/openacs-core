--
-- A simple mail queue
--
-- @author <a href="mailto:eric@openforce.net">eric@openforce.net</a>
-- @version $Id$
--

create sequence acs_mail_lite_id_seq;

CREATE TABLE acs_mail_lite_queue (
    message_id          integer
                        constraint acs_mail_lite_queue_pk
                        primary key,
    creation_date       text,
    locking_server      text,
    to_addr             text,
    cc_addr             text,
    bcc_addr            text,
    from_addr           text,
    reply_to            text,
    subject             text,
    body                text,
    package_id          integer
                        constraint amlq_package_id_fk
                        references apm_packages,
    file_ids            text,
    mime_type           text,
    object_id           integer,
    no_callback_p       boolean,
    extraheaders        text,
    use_sender_p        boolean
);

create table acs_mail_lite_mail_log (
    party_id                     integer
                                constraint amlml_party_id_fk
                                references parties (party_id)
                                on delete cascade
				constraint acs_mail_lite_log_pk
				primary key,
    last_mail_date		timestamptz default current_timestamp
);


create table acs_mail_lite_bounce (
    party_id                     integer
                                constraint amlb_party_id_fk
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
				constraint acs_mail_lite_bounce_notif_pk
				primary key,
    notification_time		timestamptz default current_timestamp,
    notification_count		integer default 0
);
