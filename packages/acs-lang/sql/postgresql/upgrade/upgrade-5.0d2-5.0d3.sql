-- Adding columns creation_user and creation_date to lang_messages
-- Need to add not-null column so re-creating table
create table lang_messages_tmp (    
    message_key        varchar(200),
    package_key        varchar(100),
    locale             varchar(30),
    message            text,
    upgrade_status     varchar(30)
);

insert into lang_messages_tmp select message_key, package_key, locale, message, upgrade_status from lang_messages;

drop table lang_messages;

create table lang_messages (    
    message_key        varchar(200)
                       constraint lang_messages_message_key_nn
                       not null,
    package_key        varchar(100)
                       constraint lang_messages_package_key_nn
                       not null,
    locale             varchar(30) 
                       constraint lang_messages_locale_fk
                       references ad_locales(locale)
                       constraint lang_messages_locale_nn
                       not null,
    message            text,
    upgrade_status     varchar(30)
                       constraint lang_messages_us_ck
                       check (upgrade_status in ('no_upgrade', 'added', 'deleted', 'updated')),
    creation_date      timestamptz 
                       default now() 
                       not null,
    creation_user      integer
                       constraint lang_messages_creation_u_fk
                       references users (user_id),
    constraint lang_messages_fk
    foreign key (message_key, package_key) 
    references lang_message_keys(message_key, package_key)
    on delete cascade,
    constraint lang_messages_pk 
    primary key (message_key, package_key, locale)
);

insert into lang_messages select message_key, package_key, locale, message, upgrade_status, now(), null from lang_messages_tmp;
