--
-- packages/language/sql/language-create.sql
--
-- @author Jeff Davis (davis@xarg.net)
-- @creation-date 2000-09-10
-- @cvs-id $Id$
--

-- ****************************************************************************
-- * The lang_messages table holds the message catalog.
-- * It is populated by ad_lang_message_register.
-- * The registered_p flag denotes that a message exists in a file
-- * that gets loaded on server startup, and hence should not get updated.
-- ****************************************************************************

begin;

create table ad_locales (
  locale		varchar(30)
                        constraint ad_locales_locale_pk
                        primary key,
  language		char(3) 
                        constraint ad_locales_language_nn
			not null,
  country		char(2) 
                        constraint ad_locales_country_nn
			not null,
  variant		varchar(30),
  label			varchar(200)
                        constraint ad_locales_label_nn
			not null
                        constraint ad_locales_label_un
                        unique,
  nls_language		varchar(30)
                        constraint ad_locale_nls_lang_nn
			not null,
  nls_territory		varchar(30),
  nls_charset		varchar(30),
  mime_charset		varchar(30),
  -- is this the default locale for its language
  default_p             boolean default 'f',
  -- Determines which locales a user can choose from for the UI
  enabled_p             boolean default 't'
);

comment on table ad_locales is '
  An OpenACS locale is identified by a language and country.
  Locale definitions in Oracle consist of a language, and optionally
  territory and character set.  (Languages are associated with default
  territories and character sets when not defined).  The formats
  for numbers, currency, dates, etc. are determined by the territory.
  language is the shortest ISO 639 code (lowercase).
  country is two letter (uppercase) abbrev is ISO 3166 country code
  mime_charset is IANA charset name
  nls_charset is  Oracle charset name
';

create view enabled_locales as
select * from ad_locales
where enabled_p = 't';

create table ad_locale_user_prefs (
  user_id               integer
                        constraint ad_locale_user_prefs_users_fk
                        references users (user_id) on delete cascade,
  package_id            integer
                        constraint lang_package_l_u_package_id_fk
                        references apm_packages(package_id) on delete cascade,
  locale                varchar(30) not null
                        constraint ad_locale_user_prefs_locale_fk
                        references ad_locales (locale) on delete cascade
);

create index ad_locale_user_prefs_user_id_idx on ad_locale_user_prefs(user_id);

-- alter user_preferences to add the locale column

alter table user_preferences add
  locale                varchar(30)
                        constraint user_preferences_locale_fk
                        references ad_locales(locale);

--
--
-- And now for some default locales
--
--

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p) 
  values ('en_US', 'English (US)', 'en', 'US', 'AMERICAN', 
          'AMERICA', 'WE8ISO8859P1', 'ISO-8859-1', 't', 't');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p) 
  values ('en_GB', 'English (GB)', 'en', 'GB', 'ENGLISH', 
          'GREAT BRITAIN', 'WE8ISO8859P1', 'ISO-8859-1', 'f', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('de_DE', 'German (DE)', 'de', 'DE', 'GERMAN', 
         'GERMANY', 'WE8ISO8859P1', 'ISO-8859-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('de_CH', 'German (CH)', 'de', 'CH', 'GERMAN', 
         'SWITZERLAND', 'WE8ISO8859P1', 'ISO-8859-1', 'f', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p) 
values ('es_ES', 'Spanish (ES)', 'es', 'ES', 'SPANISH', 
       'SPAIN', 'WE8DEC', 'ISO-8859-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p) 
values ('ast_ES', 'Asturian (ES)', 'ast', 'ES', 'SPANISH', 
       'SPAIN', 'WE8DEC', 'ISO-8859-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p) 
values ('gl_ES', 'Galician (ES)', 'gl', 'ES', 'SPANISH', 
       'SPAIN', 'WE8DEC', 'ISO-8859-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('fr_FR', 'French (FR)', 'fr', 'FR', 'FRENCH', 
        'FRANCE', 'WE8ISO8859P1', 'ISO-8859-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('ja_JP', 'Japanese (JP)', 'ja', 'JP', 'JAPANESE', 
        'JAPAN', 'JA16SJIS', 'Shift_JIS', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('da_DK', 'Danish (DK)', 'da', 'DK', 'DANISH', 'DENMARK', 'WE8ISO8859P1', 'ISO-8859-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('sv_SE', 'Swedish (SE)', 'sv', 'SE', 'SWEDISH', 'SWEDEN', 'WE8ISO8859P1', 'ISO-8859-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('fi_FI', 'Finnish (FI)', 'fi', 'FI', 'FINNISH', 'FINLAND', 'WE8ISO8859P15', 'ISO-8859-15', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('nl_NL', 'Dutch (NL)', 'nl', 'NL', 'DUTCH', 'THE NETHERLANDS', 'WE8ISO8859P1', 'ISO-8859-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('zh_CN', 'Chinese (CN)', 'zh', 'CN', 'SIMPLIFIED CHINESE', 'CHINA', 'ZHT32EUC', 'ISO-2022-CN', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('pl_PL', 'Polish (PL)', 'pl', 'PL', 'POLISH', 'POLAND', 'EE8ISO8859P2', 'ISO-8859-2', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('no_NO', 'Norwegian  (NO)', 'no', 'NO', 'NORWEGIAN', 'NORWAY', 'WE8ISO8859P1', 'ISO-8859-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('tl_PH', 'Tagalog (PH)', 'tl', 'PH', 'TAGALOG', 'PHILIPPINES', 'WE8ISO8859P1', 'ISO-8859-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('el_GR', 'Greek (GR)', 'el', 'GR', 'GREEK', 'GREECE', 'EL8ISO8859P7', 'ISO-8859-7', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('it_IT', 'Italian (IT)', 'it', 'IT', 'ITALIAN', 'ITALY', 'WE8DEC', 'ISO-8859-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('ru_RU', 'Russian (RU)', 'ru', 'RU', 'RUSSIAN', 'CIS', 'RU8PC855', 'windows-1251', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('si_LK', 'Sinhalese (LK)','si', 'LK', 'ENGLISH', 'UNITED KINGDOM', 'UTF8', 'ISO-10646-UTF-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('sh_HR', 'Serbo-Croatian (SR/HR)', 'sr', 'YU', 'SLOVENIAN', 'SLOVENIA', 'YUG7ASCII', 'ISO-8859-5', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('nn_NO', 'Norwegian (NN)','nn', 'NO', 'NORWEGIAN', 'NORWAY', 'WE8ISO8859P1', 'ISO-8859-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('pt_BR', 'Portuguese (BR)', 'pt', 'BR', 'BRAZILIAN PORTUGUESE', 'BRAZIL', 'WE8ISO8859P1', 'ISO-8859-1', 'f', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('pt_PT', 'Portuguese (PT)', 'pt', 'PT', 'PORTUGUESE', 'PORTUGAL', 'WE8ISO8859P1', 'ISO-8859-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('th_TH', 'Thai (TH)', 'th', 'TH', 'THAI', 'THAILAND', 'TH8TISASCII', 'TIS-620', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('ar_EG', 'Arabic (EG)', 'ar', 'EG', 'ARABIC', 'EGYPT', 'AR8ISO8859P6', 'ISO-8859-6', 'f', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('ar_LB', 'Arabic (LB)', 'ar', 'LB', 'ARABIC', 'LEBANON', 'AR8ISO8859P6', 'ISO-8859-6', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('tr_TR', 'Turkish (TR)', 'tr', 'TR', 'TURKISH', 'TURKEY', 'WE8ISO8859P9', 'ISO-8859-9', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('ms_MY', 'Malaysia (MY)', 'ms', 'MY', 'MALAY', 'MALAYSIA', 'US7ASCII', 'US-ASCII', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('hi_IN', 'Hindi (IN)', 'hi', 'IN', 'HINDI', 'INDIA', 'UTF8', 'UTF-8', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('ko_KR', 'Korean (KO)', 'ko', 'KR', 'KOREAN', 'KOREA', 'KO16KSC5601', 'EUC-KR', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('zh_TW', 'Chinese (TW)', 'zh', 'TW', 'TRADITIONAL CHINESE', 'TAIWAN', 'ZHT16BIG5', 'Big5', 'f', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('hu_HU', 'Hungarian (HU)', 'hu', 'HU', 'HUNGARIAN', 'HUNGARY', 'EE8ISO8859P2', 'ISO-8859-2', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('fa_IR', 'Farsi (IR)', 'fa', 'IR', 'FARSI', 'IRAN', 'AL24UTFFSS', 'windows-1256', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('ro_RO', 'Romainian (RO)', 'ro', 'RO', 'ROMAINIAN', 'ROMAINIA', 'EE8ISO8859P2', 'UTF-8', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('hr_HR', 'Croatian (HR)', 'hr', 'HR', 'CROATIAN', 'CROATIA','UTF8','UTF-8','t','f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('es_GT', 'Spanish (GT)', 'es', 'GT', 'SPANISH',  'GUATEMALA', 'WE8DEC', 'ISO-8859-1', 'f', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('eu_ES', 'Basque (ES)', 'eu', 'ES', 'SPANISH',  'SPAIN', 'WE8DEC', 'ISO-8859-1', 't', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('ca_ES', 'Catalan (ES)', 'ca', 'ES', 'SPANISH',  'SPAIN','WE8DEC', 'ISO-8859-1', 't', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('es_CO', 'Spanish (CO)', 'es', 'CO', 'SPANISH', 'COLOMBIA', 'WE8DEC', 'ISO-8859-1', 'f', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('ind_ID', 'Bahasa Indonesia (ID)', 'id', 'ID', 'INDONESIAN', 'INDONESIA', 'WEB8ISO8559P1', 'ISO-8559-1', 't', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('bg_BG', 'Bulgarian (BG)', 'bg', 'BG', 'Bulgarian', 'BULGARIAN_BULGARIA', 'CL8ISO8859P5', 'windows-1251', 't', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('pa_IN', 'Punjabi', 'pa', 'IN', 'Punjabi', 'India', 'UTF8', 'UTF-8', 't', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('fr_BE', 'French (BE)', 'fr', 'BE', 'French (Belgium)', 'Belgium', 'WE8DEC', 'ISO-8859-1', 'f', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('nl_BE', 'Dutch (BE)', 'nl', 'BE', 'Dutch (Belgium)', 'Belgium', 'WE8DEC', 'ISO-8859-1', 'f', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('en_CA', 'English (CA)', 'en', 'CA', 'English (Canada)', 'Canada', 'WE8DEC', 'ISO-8859-1', 'f', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('fr_CA', 'French (CA)', 'fr', 'CA', 'French (Canada)', 'Canada', 'WE8DEC', 'ISO-8859-1', 'f', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('zh_HK', 'Chinese, Simplified (HK)', 'zh', 'HK', 'Simplified Chinese (Hong Kong)', 'Hong Kong', 'UTF8', 'UTF-8', 'f', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('cz_CZ', 'Czech (CZ)', 'cs', 'CZ', 'Czech (Czech Republic)', 'Czech Republic', 'EE8ISO8859P2', 'ISO-8859-2', 'f', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('es_EC', 'Spanish (EC)', 'es', 'EC', 'Spanish', 'Ecuador', 'WE8DEC', 'ISO-8859-1', 'f', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('et_EE', 'Estonian (EE)', 'et', 'EE', 'Estonian', 'Estonia', 'BLT8', 'ISO-8859-15', 'f', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('is_IS', 'Icelandic (IS)', 'is', 'IS', 'Icelandic', 'Iceland', 'WE8DEC', 'ISO-8859-1', 'f', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('lt_LT', 'Lithuanian (LT)', 'lt', 'LT', 'Lithuanian', 'Lithuania', 'BLT8', 'ISO-8859-13', 'f', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('lv_LV', 'Latvian (LV)', 'lv', 'LV', 'Latvian', 'Latvia', 'BLT8', 'ISO-8859-13', 'f', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('es_MX', 'Spanish (MX)', 'es', 'MX', 'Mexican Spanish', 'Mexico', 'WE8DEC', 'ISO-8859-1', 'f', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('es_PA', 'Spanish (PA)', 'es', 'PA', 'Spanish (Panama)', 'Panama', 'WE8DEC', 'ISO-8859-1', 'f', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('es_PY', 'Spanish (PY)', 'es', 'PY', 'Spanish (Paraguay)', 'Paraguay', 'WE8DEC', 'ISO-8859-1', 'f', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('es_SV', 'Spanish (SV)', 'es', 'SV', 'Spanish (El Salvador)', 'El Salvador', 'WE8DEC', 'ISO-8859-1', 'f', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('uk_UA', 'Ukrainian (UA)', 'uk', 'UA', 'Ukrainian', 'Ukraine', 'UTF8', 'UTF-8', 'f', 'f');

insert into ad_locales
       (locale, label, language, country, nls_language, nls_territory,
        nls_charset, mime_charset, default_p, enabled_p)
 values ('es_VE', 'Spanish (VE)', 'es', 'VE', 'Spanish (Venezuela)', 'Venezuela', 'WE8DEC', 'ISO-8859-1', 'f', 'f');

end;
