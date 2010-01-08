-- Fix wrong data in ad_locales

update ad_locales set language = 'ar' where language = 'AR';
update ad_locales set language = 'ind' where locale = 'ind_ID';
update ad_locales set language = 'cs' where locale = 'cz_CZ';
update ad_locales set language = 'zh', country = 'HK' where locale = 'zh_HK';
