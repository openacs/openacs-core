--
-- packages/acs-kernel/sql/acs-create.sql
--
-- @author rhs@mit.edu
-- @creation-date 2000-08-22
-- @cvs-id acs-create.sql,v 1.1.2.9 2000/08/24 07:09:18 rhs Exp
--

create table acs_magic_objects (
	name		varchar(100)
			constraint acs_magic_objects_pk primary key,
	object_id	integer not null constraint acs_magic_objects_object_id_fk
                        references acs_objects(object_id)
);

create index acs_mo_object_id_idx on acs_magic_objects (object_id);

comment on table acs_magic_objects is '
 This table allows us to provide semantic names for certain special
 objects like the site-wide organization, and the all users party.
';

create function acs__add_user (integer,varchar,timestamptz,integer,varchar,varchar,varchar,varchar,varchar,char,char,varchar,varchar,varchar,boolean,varchar)
returns integer as '
declare
  user_id                alias for $1;  -- default null    
  object_type            alias for $2;  -- default ''user''
  creation_date          alias for $3;  -- default now()
  creation_user          alias for $4;  -- default null
  creation_ip            alias for $5;  -- default null
  email                  alias for $6;  
  url                    alias for $7;  -- default null
  first_names            alias for $8;  
  last_name              alias for $9;  
  password               alias for $10; 
  salt                   alias for $11; 
  password_question      alias for $12; -- default null
  password_answer        alias for $13; -- default null
  screen_name            alias for $14; -- default null
  email_verified_p       alias for $15; -- default ''t''
  member_state           alias for $16; -- default ''approved''
  v_user_id              users.user_id%TYPE;
  v_rel_id               membership_rels.rel_id%TYPE;
begin
    v_user_id := acs_user__new (user_id, object_type, creation_date,
				creation_user, creation_ip, email,
				url, first_names, last_name, password,
				salt, password_question, password_answer,
				screen_name, email_verified_p,null);
   
    v_rel_id := membership_rel__new (
      null,
      ''membership_rel'',
      acs__magic_object_id(''registered_users''),      
      v_user_id,
      member_state,
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
begin
    delete from users
    where user_id = remove_user__user_id;

    return 0; 
end;' language 'plpgsql';

create function acs__magic_object_id (varchar)
returns integer as '
declare
  magic_object_id__name                   alias for $1;  
  magic_object_id__object_id              acs_objects.object_id%TYPE;
begin
    select object_id
    into magic_object_id__object_id
    from acs_magic_objects
    where name = magic_object_id__name;

    return magic_object_id__object_id;
   
end;' language 'plpgsql' with(isstrict,iscachable);

-- ******************************************************************
-- * Community Core API
-- ******************************************************************

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
    (object_id, object_type)
  values
    (0, ''user'');

  insert into parties
    (party_id)
  values
    (0);

  insert into persons
    (person_id, first_names, last_name)
  values
    (0, ''Unregistered'', ''Visitor'');

  insert into users
    (user_id)
  values
    (0);

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
    ''The Public'',
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
    ''Registered Users'',
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
    null
  );

insert into acs_magic_objects
  (name, object_id)
values
  ('default_context', -3);
