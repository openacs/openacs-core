-- @author Rocael Hernandez roc@viaro.net
-- Add some new locales

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p) 
values ('es_GT', 'Spanish (GT)', 'es', 'GT', 'SPANISH', 
       'GUATEMALA', 'WE8DEC', 'ISO-8859-1', 't', 'f');

-- resolves bug 1519

----------------------------------------------------------------------
-- ch_ZH -> zh_CN

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('zh_CN', 'Chinese (CN)', 'CH', 'ZH', 'SIMPLIFIED CHINESE', 'CHINA', 'ZHT32EUC', 'ISO-2022-CN', 't', 'f');

update ad_locale_user_prefs set locale='zh_CN' where locale='ch_zh';
update lang_messages set locale='zh_CN' where locale='ch_zh';
update lang_messages_audit set locale='zh_CN' where locale='ch_zh';
update lang_translation_registry  set locale='zh_CN' where locale='ch_zh';

delete from ad_locales where locale = 'ch_zh';


----------------------------------------------------------------------
-- TH_TH -> th_TH

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('th_TH', 'Thai (TH)temp', 'th', 'TH', 'THAI', 'THAILAND', 'TH8TISASCII', 'TIS-620', 't', 'f');

update ad_locale_user_prefs set locale='th_TH' where locale='TH_TH';
update lang_messages set locale='th_TH' where locale='TH_TH';
update lang_messages_audit set locale='th_TH' where locale='TH_TH';
update lang_translation_registry  set locale='th_TH' where locale='TH_TH';

delete from ad_locales where locale = 'TH_TH';
-- reset the label to remove the unique constraint workaround
update ad_locales set label = 'Thai (TH)' where locale = 'th_TH';

----------------------------------------------------------------------
-- AR_EG -> ar_EG

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('ar_EG', 'Arabic (EG)temp', 'ar', 'EG', 'ARABIC', 'EGYPT', 'AR8ISO8859P6', 'ISO-8859-6', 'f', 'f');

update ad_locale_user_prefs set locale='ar_EG' where locale='AR_EG';
update lang_messages set locale='ar_EG' where locale='AR_EG';
update lang_messages_audit set locale='ar_EG' where locale='AR_EG';
update lang_translation_registry  set locale='ar_EG' where locale='AR_EG';

delete from ad_locales where locale = 'AR_EG';
-- reset the label to remove the unique constraint workaround
update ad_locales set label = 'Arabic (EG)' where locale = 'ar_EG';

----------------------------------------------------------------------
-- AR_LB -> ar_LB

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('ar_LB', 'Arabic (LB)temp', 'ar', 'LB', 'ARABIC', 'LEBANON', 'AR8ISO8859P6', 'ISO-8859-6', 't', 'f');

update ad_locale_user_prefs set locale='ar_LB' where locale='AR_LB';
update lang_messages set locale='ar_LB' where locale='AR_LB';
update lang_messages_audit set locale='ar_LB' where locale='AR_LB';
update lang_translation_registry  set locale='ar_LB' where locale='AR_LB';

delete from ad_locales where locale = 'AR_LB';
-- reset the label to remove the unique constraint workaround
update ad_locales set label = 'Arabic (LB)' where locale = 'ar_LB';

----------------------------------------------------------------------
-- ms_my -> ms_MY

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('ms_MY', 'Malaysia (MY)temp', 'ms', 'MY', 'MALAY', 'MALAYSIA', 'US7ASCII', 'US-ASCII', 't', 'f');


update ad_locale_user_prefs set locale='ms_MY' where locale='ms_my';
update lang_messages set locale='ms_MY' where locale='ms_my';
update lang_messages_audit set locale='ms_MY' where locale='ms_my';
update lang_translation_registry  set locale='ms_MY' where locale='ms_my';

delete from ad_locales where locale = 'ms_my';
-- reset the label to remove the unique constraint workaround
update ad_locales set label = 'Malaysia (MY)' where locale = 'ms_MY';

----------------------------------------------------------------------
-- RO_RO -> ro_RO

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('ro_RO', 'Romainian (RO)temp', 'ro', 'RO', 'ROMAINIAN', 'ROMAINIA', 'EE8ISO8859P2', 'UTF-8', 't', 'f');

update ad_locale_user_prefs set locale='ro_RO' where locale='RO_RO';
update lang_messages set locale='ro_RO' where locale='RO_RO';
update lang_messages_audit set locale='ro_RO' where locale='RO_RO';
update lang_translation_registry  set locale='ro_RO' where locale='RO_RO';

delete from ad_locales where locale = 'RO_RO';
-- reset the label to remove the unique constraint workaround
update ad_locales set label = 'Romainian (RO)' where locale = 'ro_RO';

----------------------------------------------------------------------
-- FA_IR -> fa_IR

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('fa_IR', 'Farsi (IR)temp', 'fa', 'IR', 'FARSI', 'IRAN', 'AL24UTFFSS', 'windows-1256', 't', 'f');

update ad_locale_user_prefs set locale='fa_IR' where locale='FA_IR';
update lang_messages set locale='fa_IR' where locale='FA_IR';
update lang_messages_audit set locale='fa_IR' where locale='FA_IR';
update lang_translation_registry  set locale='fa_IR' where locale='FA_IR';

delete from ad_locales where locale = 'FA_IR';
-- reset the label to remove the unique constraint workaround
update ad_locales set label = 'Farsi (IR)' where locale = 'fa_IR';


----------------------------------------------------------------------
-- HR_HR -> hr_HR

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('hr_HR', 'Croatian (HR)temp', 'hr', 'HR', 'CROATIAN', 'CROATIA','UTF8','UTF-8','t','f');

update ad_locale_user_prefs set locale='hr_HR' where locale='HR_HR';
update lang_messages set locale='hr_HR' where locale='HR_HR';
update lang_messages_audit set locale='hr_HR' where locale='HR_HR';
update lang_translation_registry  set locale='hr_' where locale='HR_HR';

delete from ad_locales where locale = 'HR_HR';
-- reset the label to remove the unique constraint workaround
update ad_locales set label = 'Croatian (HR)' where locale = 'hr_HR';


----------------------------------------------------------------------
-- trim some trailing spaces

update ad_locales set language='tr' where language='tr ';
update ad_locales set language='hi' where language='hi ';
update ad_locales set language='ko' where language='ko ';
update ad_locales set language='zh' where language='zh ';
update ad_locales set language='hu' where language='hu ';
