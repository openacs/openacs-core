alter table persons add bio varchar2(4000);

-- DRB: effing oracle

-- ******************************************************************
-- * Community Core API
-- ******************************************************************

create or replace view registered_users
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


-- faster simpler view
-- does not check for registered user/banned etc
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


declare
  bio_id integer;
  exists_count integer;
  attr_id integer;
begin

  select attribute_id into bio_id
  from acs_attributes
  where object_type = 'person' and attribute_name = 'bio';

  for user in (select user_id from users) loop
    select count(*) into exists_count
    from acs_attribute_values
    where object_id = user.user_id
      and attribute_id = bio_id;

    if exists_count > 0 then
      update persons
      set bio = (select attr_value
                 from acs_attribute_values
                 where object_id = user.user_id
                 and attribute_id = bio_id)
      where person_id = user.user_id;
    end if;
  end loop;

  delete from acs_attribute_values
  where attribute_id = bio_id;

  acs_attribute.drop_attribute ('person','bio');
  acs_attribute.drop_attribute ('person','bio_mime_type');

  attr_id := acs_attribute.create_attribute (
        object_type => 'person',
        attribute_name => 'bio',
        datatype => 'string',
        pretty_name => '#acs-kernel.Bio#',
        pretty_plural => '#acs-kernel.Bios#',
	min_n_values => 0,
	max_n_values => 1
      );

end;
/
show errors;
