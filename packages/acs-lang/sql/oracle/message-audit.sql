--
-- Auditing of messages
--
-- @author Peter Marklund
--
-- @creation-date 15 November 2002

create table lang_messages_audit (    
    message_key        varchar2(200)
                       constraint lang_messages_audit_key_nn
                       not null,
    package_key        varchar2(100)
                       constraint lang_messages_audit_p_key_nn
                       not null,
    locale             varchar2(30) 
                       constraint lang_messages_audit_l_fk
                       references ad_locales(locale)
                       constraint lang_messages_audit_l_nn
                       not null,
    message            clob,
    overwrite_date     date default sysdate not null,
    overwrite_user     integer
                       constraint lang_messages_audit_ou_fk
                       references users (user_id),
    constraint lang_messages_audit_fk
    foreign key (message_key, package_key) 
    references lang_message_keys(message_key, package_key)
    on delete cascade
);

create table lang_messages_created (
    message_key        varchar2(200)
                       constraint lang_messages_create_key_nn
                       not null,
    package_key        varchar2(100)
                       constraint lang_messages_create_p_key_nn
                       not null,
    locale             varchar2(30) 
                       constraint lang_messages_create_l_fk
                       references ad_locales(locale)
                       constraint lang_messages_create_l_nn
                       not null,
    creation_date     date default sysdate not null,
    creation_user     integer
                       constraint lang_messages_create_ou_fk
                       references users (user_id),
    constraint lang_messages_create_fk
    foreign key (message_key, package_key) 
    references lang_message_keys(message_key, package_key)
    on delete cascade
);
