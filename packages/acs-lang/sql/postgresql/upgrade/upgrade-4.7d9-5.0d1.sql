--
-- PostgreSQL upgrade script from 4.7d9 to 5.0d1
--
-- 1. Adds an enabled_p flag to ad_locales.
-- 
-- 2. Adds a comment field to lang_messages_audit
--
-- 3. Renames the lang_messages_audit.message column to 'old_message' in order to make the meaning more clear.
--
-- 4. Adds a description column to lang_message_keys.
--
-- @author Simon Carstensen (simon@collaboraid.biz)
-- @author Lars Pind (lars@collaboraid.biz)
--
-- @creation-date 2003-08-11
-- @cvs-id $Id$
--



-- 1. Adds an enabled_p flag to ad_locales.

-- New enabled_p column in ad_locales
alter table ad_locales
  add enabled_p boolean;
alter table ad_locales
alter enabled_p set default 't';

-- Let all locales be enabled for sites that are upgrading
update ad_locales set enabled_p = 't';

-- New view
create view enabled_locales as
select * from ad_locales
where enabled_p = 't';




-- 2. Adds a comment field to lang_messages_audit
-- 3. Renames the lang_messages_audit.message column to 'old_message' in order to make the meaning more clear.

create table lang_messages_audit_new (    
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
    old_message        text,
    comment_text       text,
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

insert into lang_messages_audit_new (
       message_key, 
       package_key, 
       locale, 
       old_message, 
       overwrite_date, 
       overwrite_user
) 
select message_key, 
       package_key, 
       locale, 
       message, 
       overwrite_date, 
       overwrite_user
from   lang_messages_audit;

drop table lang_messages_audit;

alter table lang_messages_audit_new rename to lang_messages_audit;

-- 4. Adds a description column to lang_message_keys.

alter table lang_message_keys add column description text;
