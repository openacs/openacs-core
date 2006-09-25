--
-- acs-kernel/sql/community-core-create.sql
--
-- Abstractions fundamental to any online community (or information
-- system, in general), derived in large part from the ACS 3.x
-- community-core data model by Philip Greenspun (philg@mit.edu), from
-- the ACS 3.x user-groups data model by Tracy Adams (teadams@mit.edu)
-- from Chapter 3 (The Enterprise and Its World) of David Hay's
-- book _Data_Model_Patterns_, and from Chapter 2 (Accountability)
-- of Martin Fowler's book _Analysis_Patterns_.
--
-- @author Michael Yoon (michael@arsdigita.com)
-- @author Rafael Schloming (rhs@mit.edu)
-- @author Jon Salz (jsalz@mit.edu)
--
-- @creation-date 2000-05-18
--
-- @cvs-id $Id$
--

-- HIGH PRIORITY:
--
-- * What can subtypes add to the specification of supertype
--   attributes? Extra constraints like "not null"? What about
--   "storage"? Can a subtype override how a given attribute is
--   stored?
--
-- * Can we realistically revoke INSERT and UPDATE permission on the
--   tables (users, persons, etc.) and make people use the PL/SQL API?
--   One downside is that it would then be difficult or impossible to
--   do things like "update ... set ... where ..." directly, without
--   creating a PL/SQL procedure to do it.
--
-- * Figure out how to migrate from ACS 3.x users, user_groups,
--   user_group_types, etc. to ACS 4.0 objects/parties/users/organizations;
--   also need to consider general_* and site_wide_* tables
--   (Rafi and Luke)
--
-- * Take an inventory of acs-kernel tables and other objects (some of which
--   may still be in /www/doc/sql/) and create their ACS 4 analogs, including
--   mapping over all general_* and site_wide_* data models, and make
--   appropriate adjustments to code
--   (Rafi and Yon/Luke/?).
--
-- * Create magic users: system and anonymous (do we actually need these?)
--
-- * Define and implement APIs
--
-- * Figure out user classes, e.g., treat "the set of parties that
--   have relationship X to object Y" as a party in its own right
--
-- * Explain why acs_rel_types, acs_rel_rules, and acs_rels are not
--   merely replicating the functionality of a relational database.
--
-- * acs_attribute_type should impose some rules on the min_n_values
--   and max_n_values columns of acs_attributes, e.g., it doesn't
--   really make sense for a boolean attribute to have more than
--   one value
--
-- * Add support for default values to acs_attributes.
--
-- * Add support for instance-specific attributes (e.g.,
--   user_group_member_fields)
--
-- MEDIUM PRIORITY:
--
-- * Read-only attributes?
--
-- * Do we need to store metadata about enumerations and valid ranges
--   or should we query the Oracle data dictionary for info on check
--   constraints?
--
-- * Create a "user_group_type" (an object_type with "organization"
--   as its supertype (do we need this?)
--
-- * Add in ancestor permission view, assuming that we'll use a
--   magical rel_type: "acs_acl"?
--
-- * How do we get all attribute values for objects of a specific
--   type? "We probably want some convention or standard way for
--   providing a view that joins supertypes and a type. This could
--   be automatically generated through metadata, or it could simply
--   be a convention." - Rafi
--
-- LOW PRIORITY:
--
-- * Formalize Rafi's definition of an "object": "A collection of rows
--   identified by an object ID for which we maintain metadata" or
--   something like that.
--
-- * "We definitely need some standard way of extending a supertype into
--   a subtype, and 'deleting' a subtype into a supertype. This will be
--   needed when we want to transform a 'person' into a registered
--   user, and do 'nuke user' but keep around the user's contributed
--   content and associate it with the 'person' part of that user. This
--   actually works quite nicely with standard oracle inheritance since
--   you can just insert or delete a row in the subtype table and
--   mutate the object type." - Rafi
--
-- ACS 4.1:
--
-- * Figure out what to do with pretty names (message catalog)
--
-- COMPLETED:
--
-- * Create magic parties: all_users (or just use null party_id?)
--   and registered_users
--
-- * Test out relationship attributes (making "relationship" an
--   acs_object_type)
--
-- * Create magic object_types (object, party, person, user,
--   organization) including attrs and rels
--
-- * Create constraints for creation_user and modifying_user

create or replace function inline_0 ()
returns integer as '
declare
  attr_id acs_attributes.attribute_id%TYPE;
begin
 --
 -- Party: the supertype of person and organization
 -- 
 PERFORM acs_object_type__create_type (
   ''party'',
   ''#acs-kernel.Party#'',
   ''#acs-kernel.Parties#'',
   ''acs_object'',
   ''parties'',
   ''party_id'',
    ''party'',
   ''f'',
   null,
   ''party__name''
   );

 attr_id := acs_attribute__create_attribute (
	''party'',
	''email'',
	''string'',
	''#acs-kernel.Email_Address#'',
	''#acs-kernel.Email_Addresses#'',
	null,
	null,
	null,
	0,
	1,
	null,
	''type_specific'',
	''f''
	);

 attr_id := acs_attribute__create_attribute (
	''party'',
	''url'',
	''string'',
	''#acs-kernel.URL#'',
	''#acs-kernel.URLs#'',
	null,
	null,
	null,
	0,
	1,
	null,
	''type_specific'',
	''f''
	);

 --
 -- Person: the supertype of user
 --
 attr_id := acs_object_type__create_type (
   ''person'',
   ''#acs-kernel.Person#'',
   ''#acs-kernel.People#'',
   ''party'',
   ''persons'',
   ''person_id'',
   ''person'',
   ''f'',
   null,
   ''person__name''
   );

 attr_id := acs_attribute__create_attribute (
        ''person'',
        ''first_names'',
        ''string'',
        ''#acs-kernel.First_Names#'',
        ''#acs-kernel.First_Names#'',
        null,
        null,
        null,
	0,
	1,
        null,
        ''type_specific'',
        ''f''
      );

 attr_id := acs_attribute__create_attribute (
        ''person'',
        ''last_name'',
        ''string'',
        ''#acs-kernel.Last_Name#'',
        ''#acs-kernel.Last_Names#'',
        null,
        null,
        null,
	0,
	1,
        null,
        ''type_specific'',
        ''f''
      );
  --
 -- User: people who have registered in the system
 --
 attr_id := acs_object_type__create_type (
   ''user'',
   ''#acs-kernel.User#'',
   ''#acs-kernel.Users#'',
   ''person'',
   ''users'',
   ''user_id'',
   ''acs_user'',
   ''f'',
   null,
   null
   );


  return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();


-- show errors

-- ******************************************************************
-- * OPERATIONAL LEVEL
-- ******************************************************************

create table parties (
	party_id	integer not null
			constraint parties_party_id_fk references
			acs_objects (object_id)
			constraint parties_party_id_pk primary key,
	email		varchar(100)
			constraint parties_email_un unique,
	url		varchar(200)
);

create index parties_email_lower_idx on parties(lower(email));

comment on table parties is '
 Party is the supertype of person and organization. It exists because
 many other types of object can have relationships to parties.
';

comment on column parties.url is '
 We store url here so that we can always make party names hyperlinks
 without joining to any other table.
';

-------------------
-- PARTY PACKAGE --
-------------------

create or replace function party__new (integer,varchar,timestamptz,integer,varchar,varchar,varchar,integer)
returns integer as '
declare
  new__party_id               alias for $1;  -- default null  
  new__object_type            alias for $2;  -- default ''party''
  new__creation_date          alias for $3;  -- default now()
  new__creation_user          alias for $4;  -- default null
  new__creation_ip            alias for $5;  -- default null
  new__email                  alias for $6;  
  new__url                    alias for $7;  -- default null
  new__context_id             alias for $8;  -- default null
  v_party_id                  parties.party_id%TYPE;
begin
  v_party_id :=
   acs_object__new(new__party_id, new__object_type, new__creation_date, 
                   new__creation_user, new__creation_ip, new__context_id,
                   ''t'', new__email, null);

  insert into parties
   (party_id, email, url)
  values
   (v_party_id, lower(new__email), new__url);

  return v_party_id;
  
end;' language 'plpgsql';

create or replace function party__delete (integer)
returns integer as '
declare
  party_id               alias for $1;  
begin
  PERFORM acs_object__delete(party_id);

  return 0; 
end;' language 'plpgsql';

create or replace function party__name (integer)
returns varchar as '
declare
  party_id               alias for $1;  
begin
  if party_id = -1 then
   return ''The Public'';
  else
   return null;
  end if;
  
end;' language 'plpgsql' immutable strict;

create or replace function party__email (integer)
returns varchar as '
declare
  email__party_id		alias for $1;
begin

  return email from parties where party_id = email__party_id;

end;' language 'plpgsql' stable strict;


-- show errors

-------------
-- PERSONS --
-------------

create table persons (
	person_id	integer not null
			constraint persons_person_id_fk
			references parties (party_id)
			constraint persons_person_id_pk primary key,
	first_names	varchar(100) not null,
	last_name	varchar(100) not null
);

comment on table persons is '
 Need to handle titles like Mr., Ms., Mrs., Dr., etc. and suffixes
 like M.D., Ph.D., Jr., Sr., III, IV, etc.
';

--------------------
-- PERSON PACKAGE --
--------------------

-- create or replace package person
-- as
-- 
--  function new (
--   person_id	in persons.person_id%TYPE default null,
--   object_type	in acs_objects.object_type%TYPE
-- 		   default 'person',
--   creation_date	in acs_objects.creation_date%TYPE
-- 		   default sysdate,
--   creation_user	in acs_objects.creation_user%TYPE
-- 		   default null,
--   creation_ip	in acs_objects.creation_ip%TYPE default null,
--   email		in parties.email%TYPE,
--   url		in parties.url%TYPE default null,
--   first_names	in persons.first_names%TYPE,
--   last_name	in persons.last_name%TYPE,
--   context_id	in acs_objects.context_id%TYPE default null
--  ) return persons.person_id%TYPE;
-- 
--  procedure delete (
--   person_id	in persons.person_id%TYPE
--  );
-- 
--  function name (
--   person_id	in persons.person_id%TYPE
--  ) return varchar2;
-- 
-- end person;

-- show errors

-- create or replace package body person
-- function new
select define_function_args('person__new','person_id,object_type;person,creation_date;now(),creation_user,creation_ip,email,url,first_names,last_name,context_id');
create or replace function person__new (integer,varchar,timestamptz,integer,varchar,varchar,varchar,varchar,varchar,integer)
returns integer as '
declare
  new__person_id              alias for $1;  -- default null  
  new__object_type            alias for $2;  -- default ''person''
  new__creation_date          alias for $3;  -- default now()
  new__creation_user          alias for $4;  -- default null
  new__creation_ip            alias for $5;  -- default null
  new__email                  alias for $6;  
  new__url                    alias for $7;  -- default null
  new__first_names            alias for $8; 
  new__last_name              alias for $9;  
  new__context_id             alias for $10; -- default null 
  v_person_id                 persons.person_id%TYPE;
begin
  v_person_id :=
   party__new(new__person_id, new__object_type,
             new__creation_date, new__creation_user, new__creation_ip,
             new__email, new__url, new__context_id);

  update acs_objects
  set title = new__first_names || '' '' || new__last_name
  where object_id = v_person_id;

  insert into persons
   (person_id, first_names, last_name)
  values
   (v_person_id, new__first_names, new__last_name);

  return v_person_id;
  
end;' language 'plpgsql';


-- procedure delete
create or replace function person__delete (integer)
returns integer as '
declare
  delete__person_id     alias for $1;  
begin
  delete from persons
  where person_id = delete__person_id;

  PERFORM party__delete(delete__person_id);

  return 0; 
end;' language 'plpgsql';


-- function name
create or replace function person__name (integer)
returns varchar as '
declare
  name__person_id        alias for $1;  
begin

  return first_names || '' '' || last_name
  from persons
  where person_id = name__person_id;

end;' language 'plpgsql' stable strict;


-- function first_names
create or replace function person__first_names (integer)
returns varchar as '
declare
  first_names__person_id        alias for $1;  
begin
  return first_names
  from persons
  where person_id = first_names__person_id;
  
end;' language 'plpgsql' stable strict;


-- function last_name
create or replace function person__last_name (integer)
returns varchar as '
declare
  last_name__person_id        alias for $1;  
begin
  return last_name
  from persons
  where person_id = last_name__person_id;

end;' language 'plpgsql' stable strict;


-- show errors

create table users (
        user_id                 integer not null
                                constraint users_user_id_fk
                                references persons (person_id)
                                constraint users_user_id_pk primary key,
        authority_id            integer
                                constraint users_authority_id_fk
                                references auth_authorities(authority_id),
        username                varchar(100) 
                                constraint users_username_nn 
                                not null,
        screen_name             varchar(100)
                                constraint users_screen_name_un
                                unique,
        priv_name               integer default 0 not null,
        priv_email              integer default 5 not null,
        email_verified_p        boolean default 't',
        email_bouncing_p        boolean default 'f' not null,
        no_alerts_until         timestamptz,
        last_visit              timestamptz,
        second_to_last_visit    timestamptz,
        n_sessions              integer default 1 not null,
        -- local authentication information
        password                char(40),
        salt                    char(40),
        password_question       varchar(1000),
        password_answer         varchar(1000),
        password_changed_date   timestamptz,
        -- used for the authentication cookie
        auth_token              varchar(100),
        -- table constraints
        constraint users_authority_username_un
        unique (authority_id, username)
);

create index users_username_lower_idx on users(lower(username));
create index users_screenname_lower_idx on users(lower(screen_name));

create table user_preferences (
	user_id			integer constraint user_preferences_user_id_fk
				references users (user_id)
				constraint user_preferences_user_id_pk
				primary key,
	prefer_text_only_p	boolean default 'f',
	-- an ISO 639 language code (in lowercase)
	language_preference	char(2) default 'en',
	dont_spam_me_p		boolean default 'f',
	email_type		varchar(64),
        locale                  varchar(30),
        timezone                varchar(100)
);

create or replace function inline_1 ()
returns integer as '
begin

  insert into acs_object_type_tables
    (object_type, table_name, id_column)
    values
    (''user'', ''user_preferences'', ''user_id'');
  return 0;
end;' language 'plpgsql';

select inline_1 ();

drop function inline_1 ();


-- show errors


alter table acs_objects add
  constraint acs_objects_creation_user_fk
  foreign key (creation_user) references users(user_id);
alter table acs_objects add
  constraint acs_objects_modifying_user_fk
  foreign key (modifying_user) references users(user_id);

comment on table users is '
 The creation_date and creation_ip columns inherited from acs_objects
 indicate when and from where the user registered. How do we apply a
 constraint ("email must not be null") to the parent type?
';

comment on column users.no_alerts_until is '
 For suppressing email alerts
';

comment on column users.last_visit is '
 Set when user reappears at site
';

comment on column users.second_to_last_visit is '
 This is what most pages query against (since last_visit will only be
 a few minutes old for most pages in a session)
';

comment on column users.n_sessions is '
 How many times this user has visited
';

----------------------
-- ACS_USER PACKAGE --
----------------------

-- create or replace package acs_user
-- as
-- 
--  function new (
--   user_id	in users.user_id%TYPE default null,
--   object_type	in acs_objects.object_type%TYPE
-- 		   default 'user',
--   creation_date	in acs_objects.creation_date%TYPE
-- 		   default sysdate,
--   creation_user	in acs_objects.creation_user%TYPE
-- 		   default null,
--   creation_ip	in acs_objects.creation_ip%TYPE default null,
--   email		in parties.email%TYPE,
--   url		in parties.url%TYPE default null,
--   first_names	in persons.first_names%TYPE,
--   last_name	in persons.last_name%TYPE,
--   password	in users.password%TYPE,
--   salt		in users.salt%TYPE,
--   password_question     in users.password_question%TYPE default null,
--   password_answer	in users.password_answer%TYPE default null,
--   screen_name	in users.screen_name%TYPE default null,
--   email_verified_p in users.email_verified_p%TYPE default 't',
--   context_id	in acs_objects.context_id%TYPE default null
--  )
--  return users.user_id%TYPE;
-- 
--  function receives_alerts_p (
--   user_id	in users.user_id%TYPE
--  )
--  return char;
-- 
--  procedure approve_email (
--   user_id	in users.user_id%TYPE
--  );
-- 
--  procedure unapprove_email (
--   user_id	in users.user_id%TYPE
--  );
-- 
--  procedure delete (
--   user_id	in users.user_id%TYPE
--  );
-- 
-- end acs_user;

-- show errors

-- create or replace package body acs_user
-- function new
select define_function_args('user__new','user_id,object_type;user,creation_date;now(),creation_user,creation_ip,authority_id,username,email,url,first_names,last_name,password,salt,screen_name,email_verified_p;t,context_id');


create or replace function acs_user__new (
    integer,      -- user_id
    varchar,      -- object_type
    timestamptz,  -- creation_date
    integer,      -- creation_user
    varchar,      -- creation_ip
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
    integer       -- context_id
)
returns integer as '
declare
    p_user_id                  alias for $1;  -- default null  
    p_object_type              alias for $2;  -- default ''user''
    p_creation_date            alias for $3;  -- default now()
    p_creation_user            alias for $4;  -- default null
    p_creation_ip              alias for $5;  -- default null
    p_authority_id             alias for $6;  -- defaults to local authority
    p_username                 alias for $7;  --
    p_email                    alias for $8;  
    p_url                      alias for $9;  -- default null
    p_first_names              alias for $10;  
    p_last_name                alias for $11;  
    p_password                 alias for $12; 
    p_salt                     alias for $13; 
    p_screen_name              alias for $14; -- default null
    p_email_verified_p         alias for $15; -- default ''t''
    p_context_id               alias for $16; -- default null
    v_user_id                  users.user_id%TYPE;
    v_authority_id             auth_authorities.authority_id%TYPE;
    v_person_exists            varchar;			
begin
    v_user_id := p_user_id;

    select case when count(*) = 0 then ''f'' else ''t'' end into v_person_exists
    from persons where person_id = v_user_id;

    if v_person_exists = ''f'' then
        v_user_id := person__new(
            v_user_id, 
            p_object_type,
            p_creation_date, 
            p_creation_user, 
            p_creation_ip,
            p_email, 
            p_url, 
            p_first_names, 
            p_last_name, 
            p_context_id
        );
    else
     update acs_objects set object_type = ''user'' where object_id = v_user_id;
    end if;

    -- default to local authority
    if p_authority_id is null then
        select authority_id
        into   v_authority_id
        from   auth_authorities
        where  short_name = ''local'';
    else
        v_authority_id := p_authority_id;
    end if;

    insert into users
       (user_id, authority_id, username, password, salt, screen_name, email_verified_p)
    values
       (v_user_id, v_authority_id, p_username, p_password, p_salt, p_screen_name, p_email_verified_p);

    insert into user_preferences
      (user_id)
      values
      (v_user_id);

    return v_user_id;
  
end;' language 'plpgsql';


create or replace function acs_user__new(varchar,varchar,varchar,char,char) 
returns integer as '
declare
        email   alias for $1;
        fname   alias for $2;
        lname   alias for $3;
        pword   alias for $4;
        salt    alias for $5;
begin
        return acs_user__new(null,
                             ''user'',
                             now(),
                             null,
                             null,                
                             email,
                             null,
                             fname,
                             lname,
                             pword,
                             salt,
                             null,
                             null,
                             null,
                             ''t'',
                             null
                             );

end;' language 'plpgsql';


-- function receives_alerts_p
create or replace function acs_user__receives_alerts_p (integer)
returns boolean as '
declare
  receives_alerts_p__user_id                alias for $1;  
  counter                                   boolean;       
begin
  select case when count(*) = 0 then ''f'' else ''t'' end into counter
   from users
   where no_alerts_until >= now()
   and user_id = receives_alerts_p__user_id;

  return counter;
  
end;' language 'plpgsql' stable;


-- procedure approve_email
create or replace function acs_user__approve_email (integer)
returns integer as '
declare
  approve_email__user_id        alias for $1;  
begin
    update users
    set email_verified_p = ''t''
    where user_id = approve_email__user_id;

    return 0; 
end;' language 'plpgsql';


-- procedure unapprove_email
create or replace function acs_user__unapprove_email (integer)
returns integer as '
declare
  unapprove_email__user_id      alias for $1;  
begin
    update users
    set email_verified_p = ''f''
    where user_id = unapprove_email__user_id;

    return 0; 
end;' language 'plpgsql';


-- procedure delete
create or replace function acs_user__delete (integer)
returns integer as '
declare
  delete__user_id       alias for $1;  
begin
  delete from user_preferences
  where user_id = delete__user_id;

  delete from users
  where user_id = delete__user_id;

  PERFORM person__delete(delete__user_id);

  return 0; 
end;' language 'plpgsql';



-- show errors
