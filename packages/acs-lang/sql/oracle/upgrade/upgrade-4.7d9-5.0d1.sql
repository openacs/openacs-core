-- New enabled_p column in ad_locales
alter table ad_locales
  add   enabled_p char(1) default 't'
        constraint ad_locale_enp_tf check(enabled_p in ('t','f'));

-- Let all locales be enabled for sites that are upgrading
update ad_locales set enabled_p = 't';

-- New view
create or replace view enabled_locales as
select * from ad_locales
where enabled_p = 't';
