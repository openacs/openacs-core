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

declare 
  attr_id acs_attributes.attribute_id%TYPE;
begin
 --
 -- Party: the supertype of person and organization
 -- 
 acs_object_type.create_type (
   supertype => 'acs_object',
   object_type => 'party',
   pretty_name => 'Party',
   pretty_plural => 'Parties',
   table_name => 'parties',
   id_column => 'party_id',
   package_name => 'party',
   name_method => 'party.name'
 );

 attr_id := acs_attribute.create_attribute (
        object_type => 'party',
        attribute_name => 'email',
        datatype => 'string',
        pretty_name => 'Email Address',
        pretty_plural => 'Email Addresses',
	min_n_values => 0,
	max_n_values => 1
      );

 attr_id := acs_attribute.create_attribute (
        object_type => 'party',
        attribute_name => 'url',
        datatype => 'string',
        pretty_name => 'URL',
        pretty_plural => 'URLs',
	min_n_values => 0,
	max_n_values => 1
      );

 --
 -- Person: the supertype of user
 --
 acs_object_type.create_type (
   supertype => 'party',
   object_type => 'person',
   pretty_name => 'Person',
   pretty_plural => 'People',
   table_name => 'persons',
   id_column => 'person_id',
   package_name => 'person',
   name_method => 'person.name'
 );

 attr_id := acs_attribute.create_attribute (
        object_type => 'person',
        attribute_name => 'first_names',
        datatype => 'string',
        pretty_name => 'First Names',
        pretty_plural => 'First Names',
	min_n_values => 0,
	max_n_values => 1
      );

 attr_id := acs_attribute.create_attribute (
        object_type => 'person',
        attribute_name => 'last_name',
        datatype => 'string',
        pretty_name => 'Last Name',
        pretty_plural => 'Last Names',
	min_n_values => 0,
	max_n_values => 1
      );

 attr_id := acs_attribute.create_attribute (
        object_type => 'person',
        attribute_name => 'bio',
        datatype => 'string',
        pretty_name => '#acs-kernel.Bio#',
        pretty_plural => '#acs-kernel.Bios#',
	min_n_values => 0,
	max_n_values => 1
      );

 --
 -- User: people who have registered in the system
 --
 acs_object_type.create_type (
   supertype => 'person',
   object_type => 'user',
   pretty_name => 'User',
   pretty_plural => 'Users',
   table_name => 'users',
   id_column => 'user_id',
   package_name => 'acs_user'
 );

 attr_id := acs_attribute.create_attribute (
        object_type => 'user',
        attribute_name => 'username',
        datatype => 'string',
        pretty_name => '#acs-kernel.Username#',
        pretty_plural => '#acs-kernel.Usernames#',
	min_n_values => 0,
	max_n_values => 1
      );

 attr_id := acs_attribute.create_attribute (
        object_type => 'user',
        attribute_name => 'screen_name',
        datatype => 'string',
        pretty_name => '#acs-kernel.Screen_Name#',
        pretty_plural => '#acs-kernel.Screen_Names#',
	min_n_values => 0,
	max_n_values => 1
      );

 commit;
end;
/
show errors

-- ******************************************************************
-- * OPERATIONAL LEVEL
-- ******************************************************************

create table parties (
	party_id	constraint parties_party_id_nn not null
			constraint parties_party_id_fk references
			acs_objects (object_id)
			constraint parties_party_id_pk primary key,
	email		varchar2(100)
			constraint parties_email_un unique,
	url		varchar2(200)
);

comment on table parties is '
 Party is the supertype of person and organization. It exists because
 many other types of object can have relationships to parties.
';

comment on column parties.url is '
 We store url here so that we can always make party names hyperlinks
 without joining to any other table.
';

-- DRB: I added this trigger to enforce the storing of e-mail in lower case.
-- party.new() already did so but I found an update that didn't...

create or replace trigger parties_in_up_tr
before insert or update on parties
for each row
begin
   :new.email := lower(:new.email);
end;
/
show errors


-------------------
-- PARTY PACKAGE --
-------------------

create or replace package party
as

 function new (
  party_id	in parties.party_id%TYPE default null,
  object_type	in acs_objects.object_type%TYPE
		   default 'party',
  creation_date	in acs_objects.creation_date%TYPE
		   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
		   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  email		in parties.email%TYPE,
  url		in parties.url%TYPE default null,
  context_id	in acs_objects.context_id%TYPE default null
 ) return parties.party_id%TYPE;

 procedure del (
  party_id	in parties.party_id%TYPE
 );

 function name (
  party_id	in parties.party_id%TYPE
 ) return varchar2;

 function email (
  party_id	in parties.party_id%TYPE
 ) return varchar2;

end party;
/
show errors


create or replace package body party
as

 function new (
  party_id	in parties.party_id%TYPE default null,
  object_type	in acs_objects.object_type%TYPE
		   default 'party',
  creation_date	in acs_objects.creation_date%TYPE
		   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
		   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  email		in parties.email%TYPE,
  url		in parties.url%TYPE default null,
  context_id	in acs_objects.context_id%TYPE default null
 )
 return parties.party_id%TYPE
 is
  v_party_id parties.party_id%TYPE;
 begin
  v_party_id :=
   acs_object.new(
     object_id => party_id,
     object_type => object_type,
     title => lower(email),
     creation_date => creation_date,
     creation_user => creation_user,
     creation_ip => creation_ip,
     context_id => context_id);

  insert into parties
   (party_id, email, url)
  values
   (v_party_id, lower(email), url);

  return v_party_id;
 end new;

 procedure del (
  party_id	in parties.party_id%TYPE
 )
 is
 begin
  acs_object.del(party_id);
 end del;

 function name (
  party_id	in parties.party_id%TYPE
 )
 return varchar2
 is
 begin
  if party_id = -1 then
   return 'The Public';
  else
   return null;
  end if;
 end name;

 function email (
  party_id	in parties.party_id%TYPE
 )
 return varchar2
 is
  v_email parties.email%TYPE;
 begin
  select email
  into v_email
  from parties
  where party_id = email.party_id;

  return v_email;

 end email;

end party;
/
show errors

-------------
-- PERSONS --
-------------

create table persons (
	person_id	constraint persons_person_id_nn not null
			constraint persons_person_id_fk
			references parties (party_id)
			constraint persons_person_id_pk primary key,
	first_names	varchar2(100) 
			constraint persons_first_names_nn not null,
	last_name	varchar2(100) 
			constraint persons_last_name_nn not null,
        bio             varchar2(4000)
);

comment on table persons is '
 Need to handle titles like Mr., Ms., Mrs., Dr., etc. and suffixes
 like M.D., Ph.D., Jr., Sr., III, IV, etc.
';

--------------------
-- PERSON PACKAGE --
--------------------

create or replace package person
as

 function new (
  person_id	in persons.person_id%TYPE default null,
  object_type	in acs_objects.object_type%TYPE
		   default 'person',
  creation_date	in acs_objects.creation_date%TYPE
		   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
		   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  email		in parties.email%TYPE,
  url		in parties.url%TYPE default null,
  first_names	in persons.first_names%TYPE,
  last_name	in persons.last_name%TYPE,
  context_id	in acs_objects.context_id%TYPE default null
 ) return persons.person_id%TYPE;

 procedure del (
  person_id	in persons.person_id%TYPE
 );

 function name (
  person_id	in persons.person_id%TYPE
 ) return varchar2;

 function first_names (
  person_id	in persons.person_id%TYPE
 ) return varchar2;

 function last_name (
  person_id	in persons.person_id%TYPE
 ) return varchar2;

end person;
/
show errors

create or replace package body person
as

 function new (
  person_id	in persons.person_id%TYPE default null,
  object_type	in acs_objects.object_type%TYPE
		   default 'person',
  creation_date	in acs_objects.creation_date%TYPE
		   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
		   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  email		in parties.email%TYPE,
  url		in parties.url%TYPE default null,
  first_names	in persons.first_names%TYPE,
  last_name	in persons.last_name%TYPE,
  context_id	in acs_objects.context_id%TYPE default null
 )
 return persons.person_id%TYPE
 is
  v_person_id persons.person_id%TYPE;
 begin
  v_person_id :=
   party.new(person_id, object_type,
             creation_date, creation_user, creation_ip,
             email, url, context_id);

  insert into persons
   (person_id, first_names, last_name)
  values
   (v_person_id, first_names, last_name);

  update acs_objects
  set title = first_names || ' ' || last_name
  where object_id = v_person_id;

  return v_person_id;
 end new;

 procedure del (
  person_id	in persons.person_id%TYPE
 )
 is
 begin
  delete from persons
  where person_id = person.del.person_id;

  party.del(person_id);
 end del;

 function name (
  person_id	in persons.person_id%TYPE
 )
 return varchar2
 is
  person_name varchar2(200);
 begin
  select first_names || ' ' || last_name
  into person_name
  from persons
  where person_id = name.person_id;

  return person_name;
 end name;

 function first_names (
  person_id	in persons.person_id%TYPE
 )
 return varchar2
 is
  person_first_names varchar2(200);
 begin
  select first_names
  into person_first_names
  from persons
  where person_id = first_names.person_id;

  return person_first_names;
 end first_names;

function last_name (
  person_id	in persons.person_id%TYPE
 )
 return varchar2
 is
  person_last_name varchar2(200);
 begin
  select last_name
  into person_last_name
  from persons
  where person_id = last_name.person_id;

  return person_last_name;
 end last_name;

end person;
/
show errors

create table users (
	user_id			not null
				constraint users_user_id_fk
				references persons (person_id)
				constraint users_user_id_pk primary key,
        authority_id            integer
                                constraint users_authority_id_fk
                                references auth_authorities(authority_id),
        username                varchar2(100) 
                                constraint users_username_nn 
                                not null,
    	screen_name		varchar2(100)
				constraint users_screen_name_un
				unique,
	priv_name		integer default 0 not null,
	priv_email		integer default 5 not null,
	email_verified_p	char(1) default 't'
				constraint users_email_verified_p_ck
				check (email_verified_p in ('t', 'f')),
	email_bouncing_p	char(1) default 'f' not null
				constraint users_email_bouncing_p_ck
				check (email_bouncing_p in ('t','f')),
	no_alerts_until		date,
	last_visit		date,
	second_to_last_visit	date,
	n_sessions		integer default 1 not null,
        -- local authentication information
	password		char(40),
	salt			char(40),
	password_question	varchar2(1000),
	password_answer		varchar2(1000),
	password_changed_date	date,
        -- used for the authentication cookie
        auth_token              varchar2(100),
        -- table constraints
        constraint users_authority_username_un
        unique (authority_id, username)
);

create index users_email_verified_idx on users (email_verified_p);

create table user_preferences (
	user_id			constraint user_preferences_user_id_fk
				references users (user_id)
				constraint user_preferences_user_id_pk
				primary key,
	prefer_text_only_p	char(1) default 'f'
				constraint user_prefs_pref_txt_only_p_ck
				check (prefer_text_only_p in ('t','f')),
	-- an ISO 639 language code (in lowercase)
	language_preference	char(2) default 'en',
	dont_spam_me_p		char(1) default 'f'
				constraint user_prefs_dont_spam_me_p_ck
				check (dont_spam_me_p in ('t','f')),
	email_type		varchar2(64),
        timezone                varchar2(100)
);

begin

  insert into acs_object_type_tables
    (object_type, table_name, id_column)
    values
    ('user', 'user_preferences', 'user_id');
end;
/
show errors;


alter table acs_objects add (
  constraint acs_objects_creation_user_fk
  foreign key (creation_user) references users(user_id),
  constraint acs_objects_modifying_user_fk
  foreign key (modifying_user) references users(user_id)
);

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

 function receives_alerts_p (
  user_id	in users.user_id%TYPE
 )
 return char;

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

 function receives_alerts_p (
  user_id in users.user_id%TYPE
 )
 return char
 is
  counter	char(1);
 begin
  select decode(count(*),0,'f','t') into counter
   from users
   where no_alerts_until >= sysdate
   and user_id = acs_user.receives_alerts_p.user_id;

  return counter;

 end receives_alerts_p;

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
