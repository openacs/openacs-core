
create function inline_0 ()
returns integer as '
declare
  one_user_id integer;
  bio_id integer;
  attr_id integer;
begin

  if exists(select 1
            from acs_attributes
            where object_type = ''person''
              and attribute_name = ''bio''
              and storage = ''type_specific'')
  then
    return 0;
  end if;

  alter table persons add bio text;

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
    and m.group_id = acs__magic_object_id(''registered_users'')
    and m.rel_id = mr.rel_id
    and m.container_id = m.group_id
    and m.rel_type = ''membership_rel'';

  bio_id := attribute_id
            from acs_attributes
            where object_type = ''person''
            and attribute_name = ''bio'';

  for one_user_id in select user_id from users loop
    if exists(select attr_value
              from acs_attribute_values
              where object_id = one_user_id
              and attribute_id = bio_id) then
      update persons
      set bio = (select attr_value
                 from acs_attribute_values
                 where object_id = one_user_id
                 and attribute_id = bio_id)
      where person_id = one_user_id;
    end if;
  end loop;

  delete from acs_attribute_values
  where attribute_id = bio_id;

  perform acs_attribute__drop_attribute (''person'',''bio'');
  perform acs_attribute__drop_attribute (''person'',''bio_mime_type'');

  attr_id := acs_attribute__create_attribute (
        ''person'',
        ''bio'',
        ''string'',
        ''#acs-kernel.Bio#'',
        ''#acs-kernel.Bios#'',
        null,
        null,
        null,
	0,
	1,
        null,
        ''type_specific'',
        ''f''
      );

  return 0;

end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();

