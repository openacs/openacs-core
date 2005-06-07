-- @author Victor Guerra
-- Fixing problem with in duplicate Default Locales for 
-- spanish(ES) and Chinese(ZH)

update ad_locales set default_p='f' where locale in ('es_GT','zh_TW'); 
