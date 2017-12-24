-- scalability/performance enchancements

create index site_nodes_parent_id_idx on site_nodes(parent_id,object_id,node_id);
create unique index users_u_id_email_verified_idx on users (user_id, email_verified_p);

create or replace view registered_users
as
  select p.email, p.url, pe.first_names, pe.last_name, u.*, mr.member_state
  from parties p, persons pe, users u, group_member_map m, membership_rels mr
  where party_id = person_id
  and person_id = user_id
  and u.user_id = m.member_id
  and m.rel_id = mr.rel_id
  and m.group_id = (select acs.magic_object_id('registered_users') from dual)
  and mr.member_state = 'approved'
  and u.email_verified_p = 't';

