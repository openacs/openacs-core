-- Make message keys cascade when packages are deleted
alter table lang_message_keys drop constraint lang_message_keys_fk;
alter table lang_message_keys
        add constraint lang_message_keys_fk
        foreign key (package_key)
        references apm_package_types(package_key)
        on delete cascade;
