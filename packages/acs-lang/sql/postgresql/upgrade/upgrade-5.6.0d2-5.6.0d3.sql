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
