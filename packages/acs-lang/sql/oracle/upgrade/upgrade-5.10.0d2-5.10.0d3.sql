begin;

drop view enabled_locales;

alter table ad_locales modify column language varchar2(3);

-- normalize eventual padding from previous life as a char(n)
update ad_locales set language = trim(language);

create or replace view enabled_locales as
select * from ad_locales
where enabled_p = 't';

end;
