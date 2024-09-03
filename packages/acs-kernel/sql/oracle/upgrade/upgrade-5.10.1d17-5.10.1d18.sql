--
-- Remove column users.no_alerts_until, refreshing the views and the
-- stored procedures definitions.
--
-- Untested!
--

drop view registered_users;
drop view acs_users_all;
drop view cc_users;

alter table users
  drop column no_alerts_until;

create or replace view registered_users
as
  select p.email, p.url, pe.first_names, pe.last_name,
  u.user_id,u.authority_id,u.username,u.password,u.salt,u.screen_name,u.priv_name,u.priv_email,u.email_verified_p,u.email_bouncing_p,u.last_visit,u.second_to_last_visit,u.n_sessions,u.password_question,u.password_answer,u.password_changed_date,
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

create or replace view acs_users_all
as
select pa.*, pe.*, u.*
from  parties pa, persons pe, users u
where  pa.party_id = pe.person_id
and pe.person_id = u.user_id;


create or replace view cc_users
as
select
o.object_id,o.object_type,o.context_id,o.security_inherit_p,o.creation_user,o.creation_date,o.creation_ip,o.last_modified,o.modifying_user,o.modifying_ip,
pa.party_id, pa.email, pa.url, 
pe.person_id, pe.first_names, pe.last_name, 
u.user_id,u.authority_id,username,u.password,u.salt,u.screen_name,u.priv_name,u.priv_email,u.email_verified_p,u.email_bouncing_p,u.last_visit,u.second_to_last_visit,u.n_sessions,u.password_question,u.password_answer,password_changed_date,
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

----------------------
-- ACS_USER PACKAGE --
----------------------

create or replace package acs_user
as

 function new (
  user_id	in users.user_id%TYPE default null,
  object_type	in acs_objects.object_type%TYPE
		   default 'user',
  creation_date	in acs_objects.creation_date%TYPE
		   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
		   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  authority_id  in auth_authorities.authority_id%TYPE default null,
  username      in users.username%TYPE,
  email		in parties.email%TYPE,
  url		in parties.url%TYPE default null,
  first_names	in persons.first_names%TYPE,
  last_name	in persons.last_name%TYPE,
  password	in users.password%TYPE,
  salt		in users.salt%TYPE,
  screen_name	in users.screen_name%TYPE default null,
  email_verified_p in users.email_verified_p%TYPE default 't',
  context_id	in acs_objects.context_id%TYPE default null
 )
 return users.user_id%TYPE;

 procedure approve_email (
  user_id	in users.user_id%TYPE
 );

 procedure unapprove_email (
  user_id	in users.user_id%TYPE
 );

 procedure del (
  user_id	in users.user_id%TYPE
 );

end acs_user;
/
show errors

create or replace package body acs_user
as

 function new (
  user_id	in users.user_id%TYPE default null,
  object_type	in acs_objects.object_type%TYPE
		   default 'user',
  creation_date	in acs_objects.creation_date%TYPE
		   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
		   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  authority_id  in auth_authorities.authority_id%TYPE default null,
  username      in users.username%TYPE,
  email		in parties.email%TYPE,
  url		in parties.url%TYPE default null,
  first_names	in persons.first_names%TYPE,
  last_name	in persons.last_name%TYPE,
  password	in users.password%TYPE,
  salt		in users.salt%TYPE,
  screen_name	in users.screen_name%TYPE default null,
  email_verified_p in users.email_verified_p%TYPE default 't',
  context_id	in acs_objects.context_id%TYPE default null
 )
 return users.user_id%TYPE
 is
  v_authority_id auth_authorities.authority_id%TYPE;
  v_user_id users.user_id%TYPE;
 begin
  v_user_id :=
   person.new(user_id, object_type,
              creation_date, creation_user, creation_ip,
              email, url,
              first_names, last_name, context_id);

  -- default to local authority
  if authority_id is null then
    select authority_id
    into   v_authority_id
    from   auth_authorities
    where  short_name = 'local';
  else
        v_authority_id := authority_id;
  end if;

  insert into users
   (user_id, authority_id, username, password, salt, screen_name, email_verified_p)
  values
   (v_user_id, v_authority_id, username, password, salt, screen_name, email_verified_p);

  insert into user_preferences
    (user_id)
    values
    (v_user_id);

  return v_user_id;
 end new;

 procedure approve_email (
  user_id	in users.user_id%TYPE
 )
 is
 begin
    update users
    set email_verified_p = 't'
    where user_id = approve_email.user_id;
 end approve_email;


 procedure unapprove_email (
  user_id	in users.user_id%TYPE
 )
 is
 begin
    update users
    set email_verified_p = 'f'
    where user_id = unapprove_email.user_id;
 end unapprove_email;

 procedure del (
  user_id	in users.user_id%TYPE
 )
 is
 begin
  delete from user_preferences
  where user_id = acs_user.del.user_id;

  delete from users
  where user_id = acs_user.del.user_id;

  person.del(user_id);
 end del;

end acs_user;
/
show errors


