alter table lang_message_keys add
    upgrade_status     varchar(30)
                       constraint lang_message_keys_us_ck
                       check (upgrade_status in ('no_upgrade', 'added','deleted'));      

alter table lang_messages add
    upgrade_status     varchar(30)
                       constraint lang_messages_us_ck
                       check (upgrade_status in ('no_upgrade', 'added', 'deleted', 'updated'));
