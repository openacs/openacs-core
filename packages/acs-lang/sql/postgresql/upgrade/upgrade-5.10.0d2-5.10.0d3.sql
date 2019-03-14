begin;

drop view enabled_locales;

alter table ad_locales alter column language set data type varchar(3);

create view enabled_locales as
select * from ad_locales
where enabled_p = 't';

end;
