alter table acs_mail_lite_queue add column package_id integer constraint acs_mail_lite_queue_pck_fk references apm_packages;
alter table acs_mail_lite_queue add column valid_email_p boolean;

create table acs_mail_lite_mail_log (
    user_id                     integer
                                constraint acs_mail_lite_log_user_id_fk
                                references users (user_id)
                                on delete cascade
                                constraint acs_mail_lite_log_pk
                                primary key,
    last_mail_date              timestamptz default current_timestamp
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
    notification_time           timestamptz default current_timestamp,
    notification_count          integer default 0
);
 