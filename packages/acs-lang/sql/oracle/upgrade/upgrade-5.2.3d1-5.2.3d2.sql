-- 
-- 
-- 
-- @author Victor Guerra (guerra@galileo.edu)
-- @creation-date 2006-01-26
-- @arch-tag: dc7aa6da-eb77-48df-9d42-6c3fb2d4ddcb
-- @cvs-id $Id$
--

--new locales for oacs-5-2

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('es_CO', 'Spanish (CO)', 'es', 'CO', 'SPANISH', 'COLOMBIA', 'WE8DEC', 'ISO-8859-1', 'f', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('ind_ID', 'Bahasa Indonesia (ID)', 'in', 'ID', 'INDONESIAN', 'INDONESIA', 'WEB8ISO8559P1', 'ISO-8559-1', 't', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('bg_BG', 'Bulgarian (BG)', 'bg', 'BG', 'Bulgarian', 'BULGARIAN_BULGARIA', 'CL8ISO8859P5', 'windows-1251', 't', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('pa_IN', 'Punjabi', 'pa', 'IN', 'Punjabi', 'India', 'UTF8', 'UTF-8', 't', 'f');
