--
-- Upgrade script from 4.1 to 4.7
--
-- Changes lang_messages so it uses locale instead of language
-- by looking up the default locale in ad_locales.
--
-- There two things that could go wrong here:
--
-- 1. There could be no locale at all for some language
--    in that case the scripts adds a new locale
-- 2. There could be no default locale
--    the script makes sure that theres is one default locale
--    pr. language 
--
-- @author Christian Hvid
--

-- Make sure that there is a default for every language

UPDATE ad_locales
SET    default_p = 't'
WHERE  (SELECT count(*) 
        FROM   ad_locales AS a 
        WHERE  a.language = ad_locales.language AND default_p='t') = 0;

-- Make sure that there is a locale for every language used in lang_messages

INSERT INTO ad_locales (language, locale, country, label, nls_language, default_p)
SELECT      language, 
            language || '_' || UPPER(language) as locale, 
             '??' as country, 
             'Locale created by upgrade-4.1-4.7 for language ' || language as label,
             '??' as nls_language, 
             't' as default_p
FROM 
  ((SELECT DISTINCT lang as language 
    FROM            lang_messages) EXCEPT
   (SELECT DISTINCT language
    FROM            ad_locales)) as new_languages;

create table temp (    
  key                     varchar(200),
  lang                    varchar(2),
  message                 text,
  registered_p            boolean
);

INSERT INTO temp(key, lang, message, registered_p) 
SELECT      key, lang, message, registered_p
FROM        lang_messages;

DROP TABLE lang_messages;

create table lang_messages (    
  key                     varchar(200),
  locale                  varchar(30) 
                          constraint lang_messages_locale_fk
                          references ad_locales(locale)
                          constraint lang_messages_locale_nn
                          not null,
  message                 text,
  registered_p            boolean,
  constraint lang_messages_pk 
  primary key (key, locale)
);

INSERT INTO lang_messages(key, locale, message, registered_p) 
SELECT      key, ad_locales.locale, message, registered_p
FROM        temp, ad_locales
WHERE       cast (ad_locales.language as text) = cast (temp.lang as text)
AND         ad_locales.default_p = 't';

DROP TABLE temp;
