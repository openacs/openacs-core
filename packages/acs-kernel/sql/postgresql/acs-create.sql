--
-- packages/acs-kernel/sql/acs-create.sql
--
-- @author rhs@mit.edu
-- @creation-date 2000-08-22
-- @cvs-id $Id$
--

create table acs_magic_objects (
	name		varchar(100)
			constraint acs_magic_objects_name_pk primary key,
	object_id	integer not null constraint acs_magic_objects_object_id_fk
                        references acs_objects(object_id)
);

comment on table acs_magic_objects is '
 This table allows us to provide semantic names for certain special
 objects like the site-wide organization, and the all users party.
';

create or replace function acs__add_user (
    integer,      -- user_id
    varchar,      -- object_type
    timestamptz,  -- creation_date
    integer,      -- creation_user
    varchar,      -- cretion_ip
    integer,      -- authority_id; default 'local'
    varchar,      -- username
    varchar,      -- email
    varchar,      -- url
    varchar,      -- first_names
    varchar,      -- last_name
    char,         -- password
    char,         -- salt
    varchar,      -- screen_name
    boolean,      -- email_verified_p
    varchar       -- member_state
)
returns integer as '
declare
    p_user_id              alias for $1;  -- default null    
    p_object_type          alias for $2;  -- default ''user''
    p_creation_date        alias for $3;  -- default now()
    p_creation_user        alias for $4;  -- default null
    p_creation_ip          alias for $5;  -- default null
    p_authority_id         alias for $6;  -- defaults to local authority
    p_username             alias for $7;  --
    p_email                alias for $8;  
    p_url                  alias for $9;  -- default null
    p_first_names          alias for $10;  
    p_last_name            alias for $11;  
    p_password             alias for $12; 
    p_salt                 alias for $13; 
    p_screen_name          alias for $14; -- default null
    p_email_verified_p     alias for $15; -- default ''t''
    p_member_state         alias for $16; -- default ''approved''
    v_user_id              users.user_id%TYPE;
    v_rel_id               membership_rels.rel_id%TYPE;
begin
    v_user_id := acs_user__new (
        p_user_id, 
        p_object_type, 
        p_creation_date,
        p_creation_user, 
        p_creation_ip, 
        p_authority_id,
        p_username,
        p_email,
        p_url, 
        p_first_names, 
        p_last_name, 
        p_password,
	p_salt, 
        p_screen_name, 
        p_email_verified_p,
        null                  -- context_id
    );
   
    v_rel_id := membership_rel__new (
      null,
      ''membership_rel'',
      acs__magic_object_id(''registered_users''),      
      v_user_id,
      p_member_state,
      null,
      null);

    PERFORM acs_permission__grant_permission (
      v_user_id,
      v_user_id,
      ''read''
      );

    PERFORM acs_permission__grant_permission (
      v_user_id,
      v_user_id,
      ''write''
      );

    return v_user_id;
   
end;' language 'plpgsql';

create function acs__remove_user (integer)
returns integer as '
declare
  remove_user__user_id                alias for $1;  
  v_rec           record;
begin
    delete
    from acs_permissions
    where grantee_id = remove_user__user_id;

    for v_rec in select rel_id
                 from acs_rels
                 where object_id_two = remove_user__user_id
    loop
        perform acs_rel__delete(v_rec.rel_id);
    end loop;

    perform acs_user__delete(remove_user__user_id);

    return 0; 
end;' language 'plpgsql';

create function acs__magic_object_id (varchar)
returns integer as '
declare
  magic_object_id__name                   alias for $1;  
begin
    return object_id
    from acs_magic_objects
    where name = magic_object_id__name;
end;' language 'plpgsql' stable strict;

-- ******************************************************************
-- * Community Core API
-- ******************************************************************

create view registered_users
as
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

-- faster simpler view
-- does not check for registered user/banned etc
create or replace view acs_users_all
as
select pa.*, pe.*, u.*
from  parties pa, persons pe, users u
where  pa.party_id = pe.person_id
and pe.person_id = u.user_id;


create view cc_users
as
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


-----------------------------------
-- Community Core Initialization --
-----------------------------------

-- The very first thing we must do is create the security_context_root
-- object.

create function inline_0 ()
returns integer as '
declare
  root_id integer;
begin

  root_id := acs_object__new (
    -4,
    ''acs_object'',
    now(),
    null,
    null,
    null,
    ''t'',
    ''#acs-kernel.lt_Security_context_root#'',
    null
    );

  insert into acs_magic_objects
   (name, object_id)
  values
   (''security_context_root'', -4);


  return root_id;

end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();


-- show errors

begin;

 --------------------------------------------------------------
 -- Some privilege that will be fundamental to all objects. --
 --------------------------------------------------------------

 select acs_privilege__create_privilege('read', null, null);
 select acs_privilege__create_privilege('write', null, null);
 select acs_privilege__create_privilege('create', null, null);
 select acs_privilege__create_privilege('delete', null, null);
 select acs_privilege__create_privilege('admin', null, null);
 select acs_privilege__create_privilege('annotate', null, null);

 ---------------------------------------------------------
 -- Administrators can read, write, create, and delete. -- 
 ---------------------------------------------------------

 select acs_privilege__add_child('admin', 'read');
 select acs_privilege__add_child('admin', 'write');
 select acs_privilege__add_child('admin', 'create');
 select acs_privilege__add_child('admin', 'delete');

end;

-- Now create our special groups and users.   We can not create the
-- relationships between these entities yet.  This is done in acs-install.sql

create function inline_2 ()
returns integer as '
declare
  v_object_id integer;
begin

  -- Make an "Unregistered Visitor" as object 0, which corresponds
  -- with the user_id assigned throughout the toolkit Tcl code

  insert into acs_objects
    (object_id, object_type, title)
  values
    (0, ''user'', ''#acs-kernel.Unregistered_Visitor#'');

  insert into parties
    (party_id)
  values
    (0);

  insert into persons
    (person_id, first_names, last_name)
  values
    (0, ''#acs-kernel.Unregistered#'', ''#acs-kernel.Visitor#'');

  insert into users
    (user_id, username)
  values
    (0, ''guest'');

  insert into acs_magic_objects
    (name, object_id)
  values
    (''unregistered_visitor'', 0);

  v_object_id := acs_group__new (
    -1,
    ''group'',
    now(),
    null,
    null,
    null,
    null,
    ''#acs-kernel.The_Public#'',
    ''closed'',
    null
  );

  insert into acs_magic_objects
   (name, object_id)
  values
   (''the_public'', -1);

  -- Add our only user, the Unregistered Visitor, to The Public
  -- group.

  perform membership_rel__new (
    null,
    ''membership_rel'',
    acs__magic_object_id(''the_public''),      
    acs__magic_object_id(''unregistered_visitor''),
    ''approved'',
    null,
    null);

  return 0;

end;' language 'plpgsql';

select inline_2 ();

drop function inline_2 ();

create function inline_3 ()
returns integer as '
declare
  group_id integer;
begin

  -- We will create the registered users group with type group for the moment
  -- because the application_group package has not yet been created.

  group_id := acs_group__new (
    -2,
    ''group'',
    now(),
    null,
    null,
    null,
    null,
    ''#acs-kernel.Registered_Users#'',
    ''closed'',
    null
  );

  insert into acs_magic_objects
   (name, object_id)
  values
   (''registered_users'', -2);

  -- Now declare "The Public" to be composed of itself and the "Registered
  -- Users" group

  perform composition_rel__new (
    null,
    ''composition_rel'',
    acs__magic_object_id(''the_public''),
    acs__magic_object_id(''registered_users''),
    null,
    null);

  return 0;
end;' language 'plpgsql';

select inline_3 ();

drop function inline_3 ();

select acs_object__new (
    -3,
    'acs_object',
    now(),
    null,
    null,
    null,
    '#acs-kernel.Default_Context#'
  );

insert into acs_magic_objects
  (name, object_id)
values
  ('default_context', -3);


--------------------------------------------------------
--
-- Authentication object
--
--------------------------------------------------------

-- Create the local authority
select authority__new(
    null,              -- authority_id
    null,              -- object_type
    'local',           -- short_name
    '#acs-kernel.OpenACS_Local#',   -- pretty_name 
    't',               -- enabled_p
    1,                 -- sort_order
    null,              -- auth_impl_id
    null,              -- pwd_impl_id
    null,              -- forgotten_pwd_url
    null,              -- change_pwd_url
    null,              -- register_impl_id
    null,              -- register_url
    null,              -- help_contact_text
    null,              -- creation_user
    null,              -- creation_ip
    null               -- context_id
);
