-- Make message keys cascade when packages are deleted
create table upgrade_temp as select * from lang_message_keys;
drop table lang_message_keys;
create table lang_message_keys ( 
    message_key        varchar(200)
                       constraint lang_message_keys_message_key_nn
                       not null,
    package_key        varchar(100)
                       constraint lang_message_keys_fk
                       references apm_package_types(package_key)
                       on delete cascade
                       constraint lang_message_keys_package_key_nn
                       not null,
    upgrade_status     varchar(30)
                       constraint lang_message_keys_us_ck
                       check (upgrade_status in ('no_upgrade', 'added','deleted')),
    constraint lang_message_keys_pk
    primary key (message_key, package_key)
);
insert into lang_message_keys select * from upgrade_temp;
drop table upgrade_temp;
