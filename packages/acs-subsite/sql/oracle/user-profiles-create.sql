--
-- packages/acs-subsite/sql/user-profiles-create.sql
--
-- @author oumi@arsdigita.com
-- @creation-date 2000-02-02
-- @cvs-id $Id$
--

-------------------------------
-- APPLICATION USER PROFILES --
-------------------------------

begin

    -- the 'user' role should already exist from the portraits stuff.
    -- acs_rel_type.create_role('user', 
    --                         'Registered User', 'Registered Users');

    acs_rel_type.create_role('application', 
                             'Application Group', 'Application Group');

    acs_rel_type.create_type(
      rel_type			=> 'user_profile',
      pretty_name		=> 'User Profile',
      pretty_plural		=> 'User Profiles',
      supertype			=> 'membership_rel',
      table_name		=> 'user_profiles',
      id_column			=> 'profile_id',
      package_name		=> 'user_profile',
      abstract_p		=> 'f',
      object_type_one		=> 'application_group',
      role_one			=> 'application',
      min_n_rels_one		=> 0,
      max_n_rels_one		=> null,
      object_type_two		=> 'user',
      role_two			=> 'user',
      min_n_rels_two		=> 0,
      max_n_rels_two		=> null
    );

end;
/
show errors


create table user_profiles (
        profile_id      constraint user_profiles_profile_id_fk
                        references membership_rels (rel_id)
                        constraint user_profiles_profile_id_pk
                        primary key
);


create or replace package user_profile
as

  function new (
    profile_id          in user_profiles.profile_id%TYPE default null,
    rel_type            in acs_rels.rel_type%TYPE default 'user_profile',
    object_id_one       in acs_rels.object_id_one%TYPE,
    object_id_two       in acs_rels.object_id_two%TYPE,
    member_state        in membership_rels.member_state%TYPE default null,
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return user_profiles.profile_id%TYPE;

  procedure del (
    profile_id      in user_profiles.profile_id%TYPE
  );

end user_profile;
/
show errors


create or replace package body user_profile
as

  function new (
    profile_id          in user_profiles.profile_id%TYPE default null,
    rel_type            in acs_rels.rel_type%TYPE default 'user_profile',
    object_id_one       in acs_rels.object_id_one%TYPE,
    object_id_two       in acs_rels.object_id_two%TYPE,
    member_state        in membership_rels.member_state%TYPE default null,
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return user_profiles.profile_id%TYPE
  is
    v_profile_id integer;
  begin

    v_profile_id := membership_rel.new (
	rel_id        => profile_id,
        rel_type      => rel_type,
        object_id_one => object_id_one,
        object_id_two => object_id_two,
        member_state  => member_state,
        creation_user => creation_user,
        creation_ip   => creation_ip
    );
    
    insert into user_profiles (profile_id) values (v_profile_id);

    return v_profile_id;
  end new;

  procedure del (
    profile_id      in user_profiles.profile_id%TYPE
  )
  is
  begin

    membership_rel.del(profile_id);

  end del;

end user_profile;
/
show errors

insert into group_type_rels
(group_rel_type_id, group_type, rel_type)
values
(acs_object_id_seq.nextval, 'application_group', 'user_profile');


-- This view is extremely fast, but for some reason its not so blaxing fast
-- when used in the registered_users_of_package_id view below.
create or replace view application_users as
  select ag.package_id, gem.element_id as user_id
  from user_profiles up,
       group_element_map gem, 
       application_groups ag
  where ag.group_id = gem.group_id
    and gem.rel_id = up.profile_id;


-- create the generalized versions of the registered_users and cc_users views:

create or replace view registered_users_of_package_id as
  select u.*, au.package_id
  from application_users au,
       registered_users u
  where au.user_id = u.user_id;

create or replace view cc_users_of_package_id as
  select u.*, au.package_id
  from application_users au,
       cc_users u
  where au.user_id = u.user_id;

