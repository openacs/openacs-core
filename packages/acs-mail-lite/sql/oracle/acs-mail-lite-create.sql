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
    user_id                     integer
                                constraint acs_mail_lite_log_user_id_fk
                                references users (user_id)
                                on delete cascade
				constraint acs_mail_lite_log_pk
				primary key,
    last_mail_date		timestamptz default current_timestamp
);


create table acs_mail_lite_bounce (
    user_id                     integer
                                constraint acs_mail_lite_bou_user_id_fk
                                references users (user_id)
                                on delete cascade
				constraint acs_mail_lite_bou_pk
				primary key,
    bounce_count		integer default 1
);


create table acs_mail_lite_bounce_notif (
    user_id                     integer
				constraint acs_mail_li_bou_notif_us_id_fk
                                references users (user_id)
                                on delete cascade
				constraint acs_mail_lite_notif_pk
				primary key,
    notification_time		timestamptz default current_timestamp,
    notification_count		integer default 0
);
