alter table acs_mail_lite_queue add (package_id integer constraint acs_mail_lite_queue_pck_fk references apm_packages);
alter table acs_mail_lite_queue add (valid_email_p varchar2(1) constraint acs_mail_lite_qu_valid_em_p_ck check (valid_email_p in ('t','f')));


create table acs_mail_lite_mail_log (
    user_id                     integer
                                constraint acs_mail_lite_log_user_id_fk
                                references users (user_id)
                                on delete cascade
                                constraint acs_mail_lite_log_pk
                                primary key,
    last_mail_date              date default sysdate
);


create table acs_mail_lite_bounce (
    user_id                     integer
                                constraint acs_mail_lite_bou_user_id_fk
                                references users (user_id)
                                on delete cascade
                                constraint acs_mail_lite_bou_pk
                                primary key,
    bounce_count                integer default 1
);


create table acs_mail_lite_bounce_notif (
    user_id                     integer
                                constraint acs_mail_li_bou_notif_us_id_fk
                                references users (user_id)
                                on delete cascade
                                constraint acs_mail_lite_notif_pk
                                primary key,
    notification_time           date default sysdate,
    notification_count          integer default 0
);
 