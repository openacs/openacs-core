-- PG 7.2 doesn't have create or replace view (7.3 does but we don't require it yet)

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


-- ******************************************************************
-- * Community Core API
-- ******************************************************************

drop view registered_users;
create view registered_users
as
  select p.email, p.url, pe.first_names, pe.last_name, u.*, mr.member_state
  from parties p, persons pe, users u, group_member_map m, membership_rels mr, acs_magic_objects amo
  where party_id = person_id
  and person_id = user_id
  and u.user_id = m.member_id
  and m.rel_id = mr.rel_id
  and amo.name = 'registered_users'
  and m.group_id = amo.object_id
  and mr.member_state = 'approved'
  and u.email_verified_p = 't';

drop view cc_users;
create view cc_users
as
select o.*, pa.*, pe.*, u.*, mr.member_state, mr.rel_id
from acs_objects o, parties pa, persons pe, users u, group_member_map m, membership_rels mr, acs_magic_objects amo
where o.object_id = pa.party_id
  and pa.party_id = pe.person_id
  and pe.person_id = u.user_id
  and u.user_id = m.member_id
  and amo.name = 'registered_users'
  and m.group_id = amo.object_id
  and m.rel_id = mr.rel_id
  and m.container_id = m.group_id;

create function acs_priv_del_tr () returns opaque as '
begin

  delete from acs_privilege_descendant_map
  where privilege = old.privilege;

  return old;

end;' language 'plpgsql';

create trigger acs_priv_del_tr before delete
on acs_privileges for each row
execute procedure acs_priv_del_tr ();

