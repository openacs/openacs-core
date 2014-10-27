-- @author Peter Marklund
-- Change the lang_messages_audit table to have a new integer primary key column
-- Add some new locales
create sequence lang_messages_audit_id_seq;

alter table lang_messages_audit add column audit_id integer;

alter table lang_messages_audit drop constraint lang_messages_audit_pk;



--
-- procedure inline_0/0
--
CREATE OR REPLACE FUNCTION inline_0(

) RETURNS integer AS $$
DECLARE
  v_rec           record;
  v_next_id       integer;
BEGIN

  for v_rec in select message_key,
                       package_key,
                       locale,
                       overwrite_date
                from lang_messages_audit
                order by overwrite_date 
  loop

        select nextval('lang_messages_audit_id_seq'::text) into v_next_id;

        update lang_messages_audit set audit_id = v_next_id
        where message_key = v_rec.message_key
          and package_key = v_rec.package_key
          and locale = v_rec.locale
          and overwrite_date = v_rec.overwrite_date;
  end loop;

  return 0;

END;
$$ LANGUAGE plpgsql;
select inline_0();
drop function inline_0();

alter table lang_messages_audit
        alter column audit_id set not null;
alter table lang_messages_audit 
        add constraint lang_messages_audit_pk primary key (audit_id);

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('hu_HU', 'Hungarian (HU)', 'hu ', 'HU', 'HUNGARIAN', 'HUNGARY', 'EE8ISO8859P2', 'ISO-8859-2', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('FA_IR', 'Farsi', 'FA ', 'IR', 'AMERICAN', 'ALGERIAN', 'AL24UTFFSS', 'windows-1256', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('RO_RO', 'Romainian', 'RO ', 'RO', 'ROMAINIAN', 'ROMAINIA', 'EE8ISO8859P2', 'UTF-8', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('HR_HR', 'Croatian', 'HR', 'HR', 'CROATIAN', 'CROATIA','UTF8','UTF-8','t','f');

-- fix http://openacs.org/bugtracker/openacs/bug?bug%5fnumber=1464
update ad_locales
        set nls_language='TAGALOG', nls_territory='PHILIPPINES'
 where locale = 'tl_PH';
