-- Create tables for languages and countries
-- 
-- The tables are filled by after_install and after_upgrade apm callbacks
-- using the iso-3166-1-countries.txt and iso-639-2_utf-8.txt files


create table language_codes (
       iso_639_2            char(3) constraint language_codes_pk primary key,
       iso_639_1            char(2),
       label                varchar(200)
);

comment on table language_codes is 'Contains ISO-639-2 language codes and their corresponding ISO-639-1 when it exists.';

create table country_codes (
       label               varchar(200),
       country             char(2) constraint country_codes_pk primary key
);

comment on table country_codes is 'Contains ISO-3166 country codes';

-- update comment on ad_locales to be more accurate about how to
-- create new locales.
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
