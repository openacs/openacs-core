ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash_algorithm
    character varying(100) DEFAULT 'salted-sha1' NOT NULL;

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

--
-- Some legacy applications might contain still the VIEW
-- "registered_users_of_package_id", which is defined in
--
--     acs-subsite/sql/postgresql/user-profiles-create.sql
--
-- This file is NOT included in new installations since over 20 years,
-- so it is not maintained and treated as a leftover from ancient
-- times.  Therefore, the view registered_users_of_package_id is not
-- recreated by this update script.
--
DROP VIEW IF EXISTS registered_users_of_package_id;

ALTER TABLE users ALTER COLUMN password TYPE character varying(128);

CREATE VIEW acs_users_all AS
SELECT pa.*, pe.*, u.*
FROM   parties pa, persons pe, users u
WHERE  pa.party_id = pe.person_id
AND    pe.person_id = u.user_id;

CREATE VIEW cc_users AS
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

CREATE VIEW registered_users AS
  select p.email, p.url, pe.first_names, pe.last_name, u.*, mr.member_state
  from parties p, persons pe, users u, group_member_map m, membership_rels mr
  where party_id = person_id
  and person_id = user_id
  and u.user_id = m.member_id
  and m.rel_id = mr.rel_id
  and m.group_id = acs__magic_object_id('registered_users')
  and m.container_id = m.group_id
  and m.rel_type = 'membership_rel'
  and mr.member_state = 'approved'
  and u.email_verified_p = 't';

--
-- Actually from acs-subsite (which is mandatory in acs-core), but
-- obsolete (see above).
--
-- CREATE VIEW registered_users_of_package_id AS
--  select u.*, au.package_id
--  from application_users au,
--       registered_users u
--  where au.user_id = u.user_id;
