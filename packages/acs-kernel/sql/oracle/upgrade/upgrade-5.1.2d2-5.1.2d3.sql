create or replace view cc_users
as
select
o.object_id,o.object_type,o.context_id,o.security_inherit_p,o.creation_user,o.creation_date,o.creation_ip,o.last_modified,o.modifying_user,o.modifying_ip,
pa.party_id, pa.email, pa.url, 
pe.person_id, pe.first_names, pe.last_name, 
u.user_id,u.authority_id,username,u.password,u.salt,u.screen_name,u.priv_name,u.priv_email,u.email_verified_p,u.email_bouncing_p,u.no_alerts_until,u.last_visit,u.second_to_last_visit,u.n_sessions,u.password_question,u.password_answer,password_changed_date,
mr.member_state, mr.rel_id
from acs_objects o, parties pa, persons pe, users u, group_member_map m, membership_rels mr
where o.object_id = pa.party_id
and pa.party_id = pe.person_id
and pe.person_id = u.user_id
and u.user_id = m.member_id
and m.group_id = (select acs.magic_object_id('registered_users') from dual)
and m.rel_id = mr.rel_id
and m.container_id = m.group_id
and m.rel_type = 'membership_rel';
