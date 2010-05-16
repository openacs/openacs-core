create index acs_objects_package_idx on acs_objects (package_id);
drop index acs_objects_package_object_idx;

-- This is necessary because a previous upgrade script didn't recreate these views.
-- The bio code didn't use these views, but they should be created for future use
-- and consistency.

drop view acs_users_all;
create view acs_users_all
as
select pa.*, pe.*, u.*
from  parties pa, persons pe, users u
where  pa.party_id = pe.person_id
and pe.person_id = u.user_id;

drop view cc_users;
create view cc_users
as
select o.*, pa.*, pe.*, u.*, mr.member_state, mr.rel_id
from acs_objects o, parties pa, persons pe, users u, group_member_map m, membership_rels mr
where o.object_id = pa.party_id
  and pa.party_id = pe.person_id
  and pe.person_id = u.user_id
  and u.user_id = m.member_id
  and m.group_id = acs__magic_object_id('registered_users')
  and m.rel_id = mr.rel_id
  and m.container_id = m.group_id
  and m.rel_type = 'membership_rel';
