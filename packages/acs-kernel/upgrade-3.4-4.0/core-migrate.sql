--    file: packages/acs-kernel/upgrade-3.4-4.0/core-migrate.sql
-- history: date            email                   message
--          2000-07-31      rhs@mit.edu             initial version

-----------
-- users --
-----------

insert into acs_objects
(object_id, object_type, creation_date, creation_ip)
select user_id, 'users', registration_date, registration_ip
from old.users;

insert into parties
(party_id, email, url)
select user_id, email, url
from old.users;

insert into persons
(person_id, first_names, last_name)
select user_id, first_names, last_name
from old.users;

insert into users
(user_id, password, screen_name, priv_name, priv_email, email_bouncing_p,
 on_vacation_until, last_visit, second_to_last_visit, n_sessions)
select user_id, password, screen_name, priv_name, priv_email, email_bouncing_p,
 on_vacation_until, last_visit, second_to_last_visit, n_sessions
from old.users;

update users set password = util.computeHASH(password);

-----------------
-- user groups --
-----------------

insert into acs_objects
(object_id, object_type, creation_user, creation_date, creation_ip,
 last_modified, modifying_user, modifying_ip)
select group_id, group_type, creation_user, registration_date,
       creation_ip_address, modification_date, modifying_user
from user_groups;

insert into parties
(party_id)
select group_id
from user_groups;
