-- packages/acs-lang/sql/oracle/upgrade/upgrade-5.4.1d1-5.4.1d2.sql
--
-- language and country codes for Canada were wrong (ca, EN/FR)

update ad_locales set language='en', country='CA' where locale='en_CA';
update ad_locales set language='fr', country='CA' where locale='fr_CA';
