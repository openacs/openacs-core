--
-- Upgrade script from 4.7d2 to 4.7d3
--
-- Split message keys and remove registered_p 


-- Copy all messages to a temporary table

create table temp (    
  key                     varchar(200),
  locale                  varchar(30),
  message                 text
);

INSERT INTO temp(key, locale, message) 
SELECT      key, locale, message
FROM        lang_messages;

-- drop old table

DROP TABLE lang_messages;

-- create new table

create table lang_message_keys ( 
    message_key        varchar(200)
                       constraint lang_message_keys_message_key_nn
                       not null,
    package_key        varchar(100)
                       constraint lang_message_keys_fk
                       references apm_package_types(package_key)
                       constraint lang_message_keys_package_key_nn
                       not null,
    constraint lang_message_keys_pk
    primary key (message_key, package_key)
);

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
    constraint lang_messages_fk
    foreign key (message_key, package_key) 
    references lang_message_keys(message_key, package_key)
    on delete cascade,
    constraint lang_messages_pk 
    primary key (message_key, package_key, locale)
);

-- insert old data

-- into lang_message_keys

INSERT INTO     lang_message_keys(message_key, package_key)
SELECT DISTINCT SUBSTR(key, STRPOS(key, '.')+1) as message_key,
                SUBSTR(key, 0, STRPOS(key, '.')) as package_key
FROM            temp, apm_package_types
WHERE           SUBSTR(key, 0, STRPOS(key, '.')) = package_key;

-- into lang_messages

INSERT INTO lang_messages(message_key, package_key, locale, message)
SELECT SUBSTR(key, STRPOS(key, '.')+1) as message_key,
       SUBSTR(key, 0, STRPOS(key, '.')) as package_key,
       locale,
       message
FROM   temp, apm_package_types
WHERE  SUBSTR(key, 0, STRPOS(key, '.')) = package_key;

DROP TABLE temp;
