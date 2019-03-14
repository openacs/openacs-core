begin;

drop view enabled_locales;

alter table ad_locales modify column language varchar2(3);

create or replace view enabled_locales as
select * from ad_locales
where enabled_p = 't';

end;
