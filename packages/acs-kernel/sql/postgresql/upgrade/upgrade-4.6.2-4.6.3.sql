drop view user_tab_comments;

create view user_tab_comments as
  select upper(c.relname) as table_name,
    case
      when c.relkind = 'r' then 'TABLE'
      when c.relkind = 'v' then 'VIEW'
      else c.relkind::text
    end as table_type,
    d.description as comments
  from pg_class c left outer join pg_description d on (c.oid = d.objoid)
  where d.objsubid = 0;

