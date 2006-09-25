
-- before release, we'll have to copy and paste from the referenced sql
-- files into this one.  For now, we just reference some sql files.

------------------------------------------------------------------------------
-- packages/acs-subsite/sql/application_groups-create.sql
--
-- @author oumi@arsdigita.com
-- @creation-date 2000-02-02
-- @cvs-id $Id$
--

------------------------
-- APPLICATION GROUPS --
------------------------


begin
        acs_object_type.create_type (
           supertype => 'group',
           object_type => 'application_group',
           pretty_name => 'Application Group',
           pretty_plural => 'Application Groups',
           table_name => 'application_groups',
           id_column => 'group_id',
           package_name => 'application_group',
           type_extension_table => 'group_types',
           name_method => 'acs_group.name'
        );
end;
/
show errors

create table application_groups (
	group_id		constraint application_groups_group_id_fk
				references groups (group_id)
				constraint application_groups_group_id_pk
				primary key,
        package_id              constraint application_groups_package_id_fk
                                references apm_packages,
                                constraint application_groups_package_id_un
                                unique (package_id)
);


create or replace package application_group
is

 function new (
  group_id              in application_groups.group_id%TYPE default null,
  object_type           in acs_objects.object_type%TYPE
                           default 'application_group',
  creation_date         in acs_objects.creation_date%TYPE
                           default sysdate,
  creation_user         in acs_objects.creation_user%TYPE
                           default null,
  creation_ip           in acs_objects.creation_ip%TYPE default null,
  email                 in parties.email%TYPE default null,
  url                   in parties.url%TYPE default null,
  group_name            in groups.group_name%TYPE,
  package_id            in application_groups.package_id%TYPE,
  context_id	in acs_objects.context_id%TYPE default null
 ) return application_groups.group_id%TYPE;

 procedure delete (
   group_id     in application_groups.group_id%TYPE
 );

 function group_id_from_package_id (
   package_id    in application_groups.group_id%TYPE,
   no_complain_p in char default 'f'
 ) return char;

end application_group;
/
show errors


create or replace package body application_group
is

 function new (
  group_id              in application_groups.group_id%TYPE default null,
  object_type           in acs_objects.object_type%TYPE
                           default 'application_group',
  creation_date         in acs_objects.creation_date%TYPE
                           default sysdate,
  creation_user         in acs_objects.creation_user%TYPE
                           default null,
  creation_ip           in acs_objects.creation_ip%TYPE default null,
  email                 in parties.email%TYPE default null,
  url                   in parties.url%TYPE default null,
  group_name            in groups.group_name%TYPE,
  package_id            in application_groups.package_id%TYPE,
  context_id	in acs_objects.context_id%TYPE default null
 )
 return application_groups.group_id%TYPE
 is
  v_group_id application_groups.group_id%TYPE;
 begin
  v_group_id := acs_group.new (
               group_id => group_id,
               object_type => object_type,
               creation_date => creation_date,
               creation_user => creation_user,
               creation_ip => creation_ip,
               email => email,
               url => url,
               group_name => group_name,
               context_id => context_id
           );

  insert into application_groups (group_id, package_id) 
    values (v_group_id, package_id);

  return v_group_id;
 end new;


 procedure delete (
    group_id     in application_groups.group_id%TYPE
 )
 is
 begin

   acs_group.delete(group_id); 

 end delete;

 function group_id_from_package_id (
   package_id    in application_groups.group_id%TYPE,
   no_complain_p in char default 'f'
 ) return char
 is
   v_group_id application_groups.group_id%TYPE;
 begin

   select group_id 
   into v_group_id
   from application_groups 
   where package_id = group_id_from_package_id.package_id;

   return v_group_id;

 exception when no_data_found then

   if no_complain_p != 't' then
     raise_application_error(-20000, 'No group_id found for package ' ||
       package_id || ' (' || acs_object.name(package_id) || ').' );
   end if;

   return null;

 end group_id_from_package_id;

end application_group;
/
show errors

insert into group_type_rels
(group_rel_type_id, group_type, rel_type)
values
(acs_object_id_seq.nextval, 'application_group', 'composition_rel');

insert into group_type_rels
(group_rel_type_id, group_type, rel_type)
values
(acs_object_id_seq.nextval, 'application_group', 'membership_rel');

-----------
-- Views --
-----------

create or replace view application_group_element_map as
select g.package_id, g.group_id, 
       m.element_id, m.container_id, m.rel_id, m.rel_type, m.ancestor_rel_type
from application_groups g,
     group_element_map m
where g.group_id = m.group_id;

create or replace view app_group_distinct_element_map as
select distinct package_id, group_id, element_id
from application_group_element_map;

create or replace view app_group_distinct_rel_map as
select distinct package_id, group_id, rel_id, rel_type, ancestor_rel_type
from application_group_element_map;

create or replace view application_group_segments as
select g.package_id, s.segment_id, s.group_id, s.rel_type, s.segment_name
from application_groups g,
     group_element_map m,
     rel_segments s
where g.group_id = m.group_id
  and m.element_id = s.group_id
UNION ALL
select g.package_id, s.segment_id, s.group_id, s.rel_type, s.segment_name
from application_groups g,
     rel_segments s
where g.group_id = s.group_id;


------------------------------------------------------------------------------
-- packages/acs-subsite/sql/user-profiles-create.sql
--
-- @author oumi@arsdigita.com
-- @creation-date 2000-02-02
-- @cvs-id $Id$
--

---------------------------
-- UPGRADE EXISTING DATA --
---------------------------

-- ACS's current system:
--
--  - Magic object -2 is the 'Registered Users' party.
--
--  - developers use the views registered_users and cc_registered_users.
--    These views join the users table with the members of group -2.
-- 
-- ACS Subsite 4.1.2 now adds a concept of users (or any party, for that 
-- matter) "belonging" to a subsite.  The upgrade to 4.1.2 needs to 
-- add all registered users to the main site.
--
-- In future versions of ACS, the registration stuff should get RIPPED OUT
-- of the kernel (Rafi agrees).  Right now, we take the path of least change.
--
-- The new and improved system:
--
--  - a group type called 'application_group' is created.  Application groups
--    have a package_id.  The application group serves as a container for
--    all parties that belong to the package_id application instance.
--    (see application-groups-create.sql)
--
--  - An application group called 'Main Site Parties' is created.  Its 
--    package_id points to the main site.
--


-- Assume that application-groups-create has already been run.

set serveroutput on;

declare
    v_package_id           integer;
    v_group_name           varchar(100);
    v_group_id             integer;
    v_rel_id               integer;
    v_segment_id           integer;
    v_segment_name         varchar(100);
begin

    dbms_output.put_line('selecting main site instance name and package_id');

    select package_id, 
           substr(instance_name, 1, 90) || ' Parties',
           substr(instance_name, 1, 60) || ' Registered Users'
    into v_package_id, v_group_name, v_segment_name
    from apm_packages, site_nodes
    where site_nodes.object_id = apm_packages.package_id
      and site_nodes.parent_id is null;
        
    dbms_output.put_line('creating main site application_group');

    v_group_id := application_group.new(
	group_name => v_group_name, 
	package_id => v_package_id
    );

    dbms_output.put_line('adding system users to main site');

    for r in (select user_id, mr.member_state
              from users, membership_rels mr, acs_rels r 
              where user_id = r.object_id_two and object_id_one = -2
                and r.rel_id = mr.rel_id ) loop

	v_rel_id := membership_rel.new (
	    object_id_one => v_group_id,
            object_id_two => r.user_id,
            member_state => r.member_state
	);	

    end loop;

    -- add all the groups in the system to the Main Site Parties group
    -- (except for 'Registered Users' and 'Main Site Parties' itself)
    for r in (select group_id
              from groups
              where not exists(select 1 from group_component_map 
                               where group_id = groups.group_id)
                and group_id not in (-2, v_group_id)) loop

	v_rel_id := composition_rel.new (
	    object_id_one => v_group_id,
            object_id_two => r.group_id
	);	

    end loop;

    -- add the 'Main Site Registered Members' segment:
    v_segment_id := rel_segment.new(
        segment_name=> v_segment_name,
        group_id => v_group_id,
        rel_type => 'membership_rel'
    );

end;
/
show errors

--------------------------------------------------------------
-- acs-subsite-create.sql
-- oumi@arsdigita.com
-- 2/20/2001
--
-- CHANGES
--
-- Added party_names view.
--------------------------------------------------------------

-- This view lets us avoid using acs_object.name to get party_names.
-- 
create or replace view party_names
as
select p.party_id,
       decode(groups.group_id,
              null, decode(persons.person_id, 
                           null, p.email,
                           persons.first_names || ' ' || persons.last_name),
              groups.group_name) as party_name
from parties p,
     groups,
     persons
where p.party_id = groups.group_id(+)
  and p.party_id = persons.person_id(+);




--------------------------------------------------------------
-- subsite-callbacks-create.sql
-- mbryzek@arsdigita.com
-- 2/20/2001
--------------------------------------------------------------

-- /packages/acs-subsite/sql/subsite-group-callbacks-create.sql

-- Defines a simple callback system to allow other applications to
-- register callbacks when groups of a given type are created. 

-- Copyright (C) 2001 ArsDigita Corporation
-- @author Michael Bryzek (mbryzek@arsdigita.com)
-- @creation-date 2001-02-20

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html


-- What about instead of? 
   -- insead_of viewing the group, go to the portal
   -- instead of inserting the group with package_instantiate_object, go here 

create table subsite_callbacks (
       callback_id         integer 
			   constraint sgc_callback_id_pk primary key,
       event_type          varchar(100) not null
			   constraint sgc_event_type_ck check(event_type in ('insert','update','delete')),
       object_type         varchar(100) not null
			   constraint sgc_object_type_fk references acs_object_types
                           on delete cascade,
       callback		   varchar(300) not null,
       callback_type       varchar(100) not null
			   constraint sgc_callback_type_ck check(callback_type in ('tcl')),
       sort_order          integer default(1) not null
			   constraint sgc_sort_order_ck check(sort_order >= 1),
       -- allow only one callback of a given type for given 
       constraint subsite_callbacks_un unique (object_type, event_type, callback_type, callback)
);

comment on table subsite_callbacks is '
	Applications can register callbacks that are triggered
	whenever a group of a specified type is created. The callback
	must expect the following arguments: 
	  * object_id: The object that just got created
	  * node_id: The node_id where the object got created
	  * package_id: The package_id from where the object got created
	These are passed in the following way:
	  * tcl procedure: Using named parameters (e.g. -object_id $object_id)
	All callbacks must accept all of these parameters.
';

comment on column subsite_callbacks.event_type is '
	The type of event we are monitoring. The keywords here are used
	by the applications to determine which callbacks to trigger.
';      

comment on column subsite_callbacks.object_type is '
	The object type to monitor. Whenever an object of this type is
	created, the subsite package will check for a registered
	callbacks.
';

comment on column subsite_callbacks.callback_type is ' 
	The type of the callback. This determines how the callback is
	executed. Currenlty only a tcl type is supported but other
	types may be added in the future. 
';


comment on column subsite_callbacks.callback is '
	The actual callback. This can be the name of a plsql function
	or procedure, a url stub relative to the node at which package
	id is mounted, or the name of a tcl function.
';

comment on column subsite_callbacks.sort_order is '
	The order in which the callbacks should fire. This is
	important when you need to ensure that one event fires before
	another (e.g. you must mount a portals application before the
	bboard application)
';      


create or replace package subsite_callback as

  function new (
  --/** Registers a new callback. If the same callback exists as
  --    defined in the unique constraint on the table, does 
  --    nothing but returns the existing callback_id.
  -- 
  --    @author Michael Bryzek (mbryzek@arsdigita.com)
  --    @creation-date 2001-02-20
  -- 
  --*/
       callback_id         IN subsite_callbacks.callback_id%TYPE default null,
       event_type          IN subsite_callbacks.event_type%TYPE,
       object_type         IN subsite_callbacks.object_type%TYPE,
       callback		   IN subsite_callbacks.callback%TYPE,
       callback_type       IN subsite_callbacks.callback_type%TYPE,
       sort_order          IN subsite_callbacks.sort_order%TYPE default null
  ) return subsite_callbacks.callback_id%TYPE;

  procedure delete (
  --/** Deletes the specified callback
  -- 
  --    @author Michael Bryzek (mbryzek@arsdigita.com)
  --    @creation-date 2001-02-20
  -- 
  --*/
  
       callback_id         IN subsite_callbacks.callback_id%TYPE
  );

end subsite_callback;
/
show errors;



create or replace package body subsite_callback as

  function new (
       callback_id         IN subsite_callbacks.callback_id%TYPE default null,
       event_type          IN subsite_callbacks.event_type%TYPE,
       object_type         IN subsite_callbacks.object_type%TYPE,
       callback		   IN subsite_callbacks.callback%TYPE,
       callback_type       IN subsite_callbacks.callback_type%TYPE,
       sort_order          IN subsite_callbacks.sort_order%TYPE default null
  ) return subsite_callbacks.callback_id%TYPE
  IS
    v_callback_id  subsite_callbacks.callback_id%TYPE;
    v_sort_order   subsite_callbacks.sort_order%TYPE;
  BEGIN

    if new.callback_id is null then
       select acs_object_id_seq.nextval into v_callback_id from dual;
    else
       v_callback_id := new.callback_id;
    end if;
   
    if new.sort_order is null then
       -- Make this the next event for this object_type/event_type combination
       select nvl(max(sort_order),0) + 1 into v_sort_order
         from subsite_callbacks
        where object_type = new.object_type
          and event_type = new.event_type;
    else
       v_sort_order := new.sort_order;
    end if;

    begin 
      insert into subsite_callbacks
      (callback_id, event_type, object_type, callback, callback_type, sort_order)
      values
      (v_callback_id, new.event_type, new.object_type, new.callback, new.callback_type, v_sort_order);
     exception when dup_val_on_index then
      select callback_id into v_callback_id
        from subsite_callbacks
       where event_type = new.event_type
         and object_type = new.object_type
         and callback_type = new.callback_type
         and callback = new.callback;
    end;
    return v_callback_id;

  END new;


  procedure delete (
       callback_id         IN subsite_callbacks.callback_id%TYPE
  )
  is
  begin
     delete from subsite_callbacks where callback_id=subsite_callback.delete.callback_id;
  end delete;

end subsite_callback;
/
show errors;


