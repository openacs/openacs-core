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


@@ complex-create
