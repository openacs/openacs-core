alter table lang_message_keys add
    upgrade_status     varchar(30)
                       constraint lang_message_keys_us_ck
                       check (upgrade_status in ('no_upgrade', 'added','deleted'));      

alter table lang_messages add
    upgrade_status     varchar(30)
                       constraint lang_messages_us_ck
                       check (upgrade_status in ('no_upgrade', 'added', 'deleted', 'updated'));

create table lang_messages_audit (    
    message_key        varchar(200)
                       constraint lang_messages_audit_key_nn
                       not null,
    package_key        varchar(100)
                       constraint lang_messages_audit_p_key_nn
                       not null,
    locale             varchar(30) 
                       constraint lang_messages_audit_l_fk
                       references ad_locales(locale)
                       constraint lang_messages_audit_l_nn
                       not null,
    message            text,
    overwrite_date     timestamptz 
                       default now() 
                       not null,
    overwrite_user     integer
                       constraint lang_messages_audit_ou_fk
                       references users (user_id),
    constraint lang_messages_audit_fk
    foreign key (message_key, package_key) 
    references lang_message_keys(message_key, package_key)
    on delete cascade
);
