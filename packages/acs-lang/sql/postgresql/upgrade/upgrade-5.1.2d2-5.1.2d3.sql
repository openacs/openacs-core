-- @author Joel Aufrecht 
-- Add new locales

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
values ('eu_ES', 'Basque (ES)', 'eu', 'ES', 'SPANISH',  'SPAIN', 'WE8DEC', 'ISO-8859-1', 't', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
values ('ca_ES', 'Catalan (ES)', 'ca', 'ES', 'SPANISH',  'SPAIN','WE8DEC', 'ISO-8859-1', 't', 'f');

