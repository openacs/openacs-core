-- Upgrade script that adds new locale from the dotLRN translation server

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p)
 values ('fi_FI', 'Finnish (FI)', 'fi', 'FI', 'FINNISH', 'FINLAND', 'WE8ISO8859P15', 'ISO-8859-15', 't');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p)
 values ('nl_NL', 'Dutch (NL)', 'nl', 'NL', 'DUTCH', 'THE NETHERLANDS', 'WE8ISO8859P1', 'ISO-8859-1', 't');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p)
 values ('ch_zh', 'Chinese (ZH)', 'CH', 'ZH', 'SIMPLIFIED CHINESE', 'CHINA', 'ZHT32EUC', 'ISO-2022-CN', 't');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p)
 values ('pl_PL', 'Polish (PL)', 'pl', 'PL', 'POLISH', 'POLAND', 'EE8ISO8859P2', 'ISO-8859-2', 't');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p)
 values ('no_NO', 'Norwegian  (NO)', 'no', 'NO', 'NORWEGIAN', 'NORWAY', 'WE8ISO8859P1', 'ISO-8859-1', 't');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p)
 values ('tl_PH', 'Tagalog (PH)', 'tl', 'PH', 'AMERICAN', 'ALGERIA', 'WE8ISO8859P1', 'ISO-8859-1', 't');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p)
 values ('el_GR', 'Greek (GR)', 'el', 'GR', 'GREEK', 'GREECE', 'EL8ISO8859P7', 'ISO-8859-7', 't');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p)
 values ('it_IT', 'Italian (IT)', 'it', 'IT', 'ITALIAN', 'ITALY', 'WE8DEC', 'ISO-8859-1', 't');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p)
 values ('ru_RU', 'Russian (RU)', 'ru', 'RU', 'RUSSIAN', 'CIS', 'RU8PC855', 'windows-1251', 't');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p)
 values ('si_LK', 'Sinhalese (LK)','si', 'LK', 'ENGLISH', 'UNITED KINGDOM', 'UTF8', 'ISO-10646-UTF-1', 't');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p)
 values ('sh_HR', 'Serbo-Croatian (SR/HR)', 'sr', 'YU', 'SLOVENIAN', 'SLOVENIA', 'YUG7ASCII', 'ISO-8859-5', 't');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p)
 values ('nn_NO', 'Norwegian (NN)','nn', 'NO', 'NORWEGIAN', 'NORWAY', 'WE8ISO8859P1', 'ISO-8859-1', 't');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p)
 values ('pt_BR', 'Portuguese (BR)', 'pt', 'BR', 'BRAZILIAN PORTUGUESE', 'BRAZIL', 'WE8ISO8859P1', 'ISO-8859-1', 't'
);

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p)
 values ('TH_TH', 'Thai (TH)', 'th', 'TH', 'THAI', 'THAILAND', 'TH8TISASCII', 'TIS-620', 't');

-- Forgot to add this locale earlier, some installations may have it already
declare
  v_locale_exists_p integer;
begin
	select count(*) into v_locale_exists_p 
	from ad_locales where locale = 'sv_SE';


	if v_locale_exists_p = 0 then
	  insert into ad_locales 
       	  (locale, label, language, country, nls_language, nls_territory, 
       	   nls_charset, mime_charset, default_p)
 	  values ('sv_SE', 'Swedish (SE)', 'sv', 'SE', 'SWEDISH', 'SWEDEN', 
	        'WE8ISO8859P1', 'ISO-8859-1', 't');
	end if;
end;
/
show errors
