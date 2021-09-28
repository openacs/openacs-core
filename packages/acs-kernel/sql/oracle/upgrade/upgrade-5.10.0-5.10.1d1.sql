ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash_algorithm
    varchar2(100) DEFAULT 'salted-sha1' NOT NULL;

--
-- String length of "pbkdf2-hmac-sha2" is 64 bytes. If scrypt or
-- pbkdf2_hmac with sha3-512 would be used, the hash size would be 128
-- bytes, so let us prepare for this.  Since the VIEWs
-- "acs_users_all", "cc_users" and "registered_users" depend on on
-- column "password", we have to drop and recreate these.
--

DROP VIEW acs_users_all;
DROP VIEW cc_users;
DROP VIEW registered_users;

ALTER TABLE users MODIFY password varchar2(128);

CREATE OR REPLACE view acs_users_all
as
select pa.*, pe.*, u.*
from  parties pa, persons pe, users u
where  pa.party_id = pe.person_id
and pe.person_id = u.user_id;

CREATE OR REPLACE VIEW cc_users
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

CREATE OR REPLACE VIEW registered_users
as
  select p.email, p.url, pe.first_names, pe.last_name,
  u.user_id,u.authority_id,u.username,u.password,u.salt,u.screen_name,u.priv_name,u.priv_email,u.email_verified_p,u.email_bouncing_p,u.no_alerts_until,u.last_visit,u.second_to_last_visit,u.n_sessions,u.password_question,u.password_answer,u.password_changed_date,
  mr.member_state
  from parties p, persons pe, users u, group_member_map m, membership_rels mr
  where party_id = person_id
  and person_id = user_id
  and u.user_id = m.member_id
  and m.rel_id = mr.rel_id
  and m.group_id = (select acs.magic_object_id('registered_users') from dual)
  and m.container_id = m.group_id
  and m.rel_type = 'membership_rel'
  and mr.member_state = 'approved'
  and u.email_verified_p = 't';
