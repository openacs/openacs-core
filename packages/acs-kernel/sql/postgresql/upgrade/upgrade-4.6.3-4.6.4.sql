--
-- Upgrade script for version 4.6.3 to 4.6.4
--
-- Adds password expiration
--
-- @author Lars Pind (lars@collaboraid.biz)
-- @creation-date 2003-05-28
-- @cvs-id $Id$
--


-- add the column

alter table users add password_changed_date timestamptz ;

alter table users alter column password_changed_date set default now();

-- looks like you cannot add a not null constraint to PG
--alter table users add constraint users_pwd_chg_date_nn (password_changed_date not null);


-- set default value to today

update users set password_changed_date = current_timestamp;


-- recreate the registered_users view

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


-- recreate the cc_users view

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

