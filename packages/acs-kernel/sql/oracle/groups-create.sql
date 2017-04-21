--
-- packages/acs-kernel/sql/groups-create.sql
--
-- @author rhs@mit.edu
-- @creation-date 2000-08-22
-- @cvs-id $Id$
--

----------------------------
-- GROUP TYPES AND GROUPS --
----------------------------

-- NOTE: developers should not do dml to manipulate/add/delete membership
-- or composition relations. Use the APIs (the composition_rel and 
-- membership_rel pl/sql packages).  In particular, NEVER UPDATE object_id_one
-- and object_id_two of acs_rels, or you'll break the denormalization (see
-- the "DENORMALIZATION" section further below).

create table composition_rels (
        rel_id          constraint composition_rels_rel_id_fk
                        references acs_rels (rel_id)
                        constraint composition_rels_rel_id_pk
                        primary key
);

create table membership_rels (
        rel_id          constraint membership_rels_rel_id_fk
                        references acs_rels (rel_id)
                        constraint membership_rels_rel_id_pk
                        primary key,
        member_state    varchar2(20) 
			constraint mr_member_state_nn not null
                        constraint mr_member_state_ck
                        check (member_state in ('merged','approved', 'needs approval',
                                              'banned', 'rejected', 'deleted'))
);

create table admin_rels (
        rel_id          integer constraint admin_rels_rel_id_fk
                        references membership_rels (rel_id)
                        constraint admin_rels_rel_id_pk
                        primary key
);


create index member_rels_member_state_idx on membership_rels (member_state);

declare
  attr_id acs_attributes.attribute_id%TYPE;
begin
 --
 -- Group: a composite party
 --
 acs_object_type.create_type (
   supertype => 'party',
   object_type => 'group',
   pretty_name => 'Group',
   pretty_plural => 'Groups',
   table_name => 'groups',
   id_column => 'group_id',
   package_name => 'acs_group',
   type_extension_table => 'group_types',
   name_method => 'acs_group.name'
 );

 attr_id := acs_attribute.create_attribute (
        object_type => 'group',
        attribute_name => 'group_name',
        datatype => 'string',
        pretty_name => 'Group name',
        pretty_plural => 'Group names',
	min_n_values => 1,
	max_n_values => 1
      );

 --
 -- Composition Relationship
 --
 acs_rel_type.create_role ('composite', 'Composite', 'Composites');
 acs_rel_type.create_role('component', 'Component', 'Components');

 acs_rel_type.create_type (
   rel_type => 'composition_rel',
   pretty_name => 'Composition Relation',
   pretty_plural => 'Composition Relationships',
   table_name => 'composition_rels',
   id_column => 'rel_id',
   package_name => 'composition_rel',
   object_type_one => 'group', role_one => 'composite',
   min_n_rels_one => 0, max_n_rels_one => null,
   object_type_two => 'group', role_two => 'component',
   min_n_rels_two => 0, max_n_rels_two => null,
   composable_p => 't'
 );

 --
 -- Membership Relationship
 --
 acs_rel_type.create_role ('member', '#acs-kernel.member_role_pretty_name#', '#acs-kernel.member_role_pretty_plural#');

 acs_rel_type.create_type (
   rel_type => 'membership_rel',
   pretty_name => 'Membership Relation',
   pretty_plural => 'Membership Relationships',
   table_name => 'membership_rels',
   id_column => 'rel_id',
   package_name => 'membership_rel',
   object_type_one => 'group',
   min_n_rels_one => 0, max_n_rels_one => null,
   object_type_two => 'person', role_two => 'member',
   min_n_rels_two => 0, max_n_rels_two => null,
   composable_p => 't'
 );

 acs_rel_type.create_role ('admin', 'Administrator', 'Administrators');

 acs_rel_type.create_type (
   rel_type => 'admin_rel',
   pretty_name => 'Administrator Relation',
   pretty_plural => 'Administrator Relationships',
   supertype => 'membership_rel',
   table_name => 'admin_rels',
   id_column => 'rel_id',
   package_name => 'admin_rel',
   object_type_one => 'group',
   min_n_rels_one => 0, max_n_rels_one => null,
   object_type_two => 'person', role_two => 'admin',
   min_n_rels_two => 0, max_n_rels_two => null,
   composable_p => 'f'
 );

 commit;
end;
/
show errors

create table group_types (
        group_type      constraint group_types_group_type_nn not null
                        constraint group_types_group_type_pk primary key
                        constraint group_types_group_type_fk
                        references acs_object_types (object_type),
        default_join_policy  varchar2(30) default 'open' 
			constraint gt_default_join_policy_nn not null
                        constraint gt_default_join_policy_ck
                        check (default_join_policy in 
                               ('open', 'needs approval', 'closed'))
);

comment on table group_types is '
 This table holds additional knowledge level attributes for the
 group type and its subtypes.
';

create table groups (
        group_id        constraint groups_group_id_nn not null
                        constraint groups_group_id_fk
                        references parties (party_id)
                        constraint groups_group_id_pk primary key,
        group_name      varchar2(1000) 
			constraint groups_group_name_nn not null,
        join_policy     varchar2(30) default 'open' 
			constraint groups_join_policy_nn not null
                        constraint groups_join_policy_ck
                        check (join_policy in 
                               ('open', 'needs approval', 'closed')),
        description     varchar2(4000)
);



create table group_type_rels (
       group_rel_type_id      integer constraint gtr_group_rel_type_id_pk primary key,
       rel_type		      constraint group_type_rels_rel_type_nn not null 
                              constraint group_type_rels_rel_type_fk
                              references acs_rel_types (rel_type)
                              on delete cascade,
       group_type	      constraint group_type_rels_group_type_nn not null 
                              constraint group_type_rels_group_type_fk
                              references acs_object_types (object_type)
                              on delete cascade,
       constraint gtr_group_rel_types_un unique (group_type, rel_type)
);

-- rel_type references acs_rel_types. Create an index
create index group_type_rels_rel_type_idx on group_type_rels(rel_type);

comment on table group_type_rels is '
  Stores the default relationship types available for use by groups of
  a given type. We May want to generalize this table to object_types and
  put it in the relationships sql file, though there is no need to do so
  right now.
';


create table group_rels (
       group_rel_id           integer constraint group_rels_group_rel_id_pk primary key,
       rel_type		      constraint group_rels_rel_type_nn not null 
                              constraint group_rels_rel_type_fk
                              references acs_rel_types (rel_type)
                              on delete cascade,
       group_id	              constraint group_rels_group_id_nn not null 
                              constraint group_rels_group_id_fk
                              references groups (group_id)
                              on delete cascade,
       constraint group_rels_group_rel_type_un unique (group_id, rel_type)
);

-- rel_type references acs_rel_types. Create an index
create index group_rels_rel_type_idx on group_rels(rel_type);

comment on table group_rels is '
  Stores the relationship types available for use by each group. Only
  relationship types in this table are offered for adding
  relations. Note that there is no restriction that says groups can
  only have relationship types specified for their group type. The
  <code>group_type_rels</code> table just stores defaults for groups
  of a new type.
';


------------------------------------------
-- DENORMALIZATION: group_element_index --
------------------------------------------

-- group_element_index is an internal mapping table maintained by the 
-- parties system for optimizaiton of the views in the "VIEWS" section 
-- further below.

-- Instead of writing a complicated trigger to keep this map up to
-- date when people edit membership or composition relationships, I
-- think I'm going to make it illegal to mutate membership or
-- composition relationships, or at least the object_id_one and
-- object_id_two columns, since I don't know that it makes sense
-- anyways. Also, by making this constraint we can probably do some
-- nifty optimizaitons at some point in the future.

-- This means, you can't edit a membership or composition relation. 
-- Instead, you have to delete the relation and recreate it. By doing this, 
-- we only have "on insert" and "on delete" triggers and avoid maintaining 
-- the more complex "on update" trigger"

create table group_element_index (
	group_id	constraint gei_group_id_nn not null
			constraint group_element_index_grp_id_fk
			references groups (group_id)
                        on delete cascade,
	element_id	constraint gei_element_id_nn not null
			constraint group_element_index_elem_id_fk
			references parties (party_id),
	rel_id		constraint group_element_index_rel_id_nn not null
			constraint group_element_index_rel_id_fk
			references acs_rels (rel_id)
                        on delete cascade,
	container_id	constraint gei_container_id_nn not null
			constraint group_element_index_cont_id_fk
			references groups (group_id),
        rel_type        constraint gei_rel_type_nn not null
                        constraint group_elem_index_rel_type_fk
                        references acs_rel_types (rel_type),
        ancestor_rel_type varchar2(100) 
			constraint gei_ancestor_rel_type_nn not null
                        constraint gei_ancestor_rel_type_ck
                        check (ancestor_rel_type in ('composition_rel','membership_rel')),
	constraint group_element_index_pk
	primary key (element_id, group_id, rel_id)
) organization index;

create index group_elem_idx_group_idx on group_element_index (group_id);
create index group_elem_idx_element_idx on group_element_index (element_id);
create index group_elem_idx_rel_id_idx on group_element_index (rel_id);
create index group_elem_idx_rel_type_idx on group_element_index (rel_type);

-- The index on container_id is not very good
-- and in some cases can be quite detrimental
-- see http://openacs.org/forums/message-view?message_id=142769
-- create index group_elem_idx_container_idx on group_element_index (container_id);


comment on table group_element_index is '
 This table is for internal use by the parties system.  It as an auxiliary
 table, a denormalization of data, that is used to improve performance.
 Do not query on this table or insert into it.  Query on group_element_map
 instead.  And insert by using the API''s for membership_rel, composition_rel, 
 or some sub-type of those relationship types.
';


-----------
-- VIEWS --
-----------

create or replace view group_element_map
as select group_id, element_id, rel_id, container_id, 
          rel_type, ancestor_rel_type
   from group_element_index;

create or replace view group_component_map
as select group_id, element_id as component_id, rel_id, container_id, rel_type
   from group_element_map
   where ancestor_rel_type='composition_rel';

create or replace view group_member_map
as select group_id, element_id as member_id, rel_id, container_id, rel_type
   from group_element_map
   where ancestor_rel_type='membership_rel';

create or replace view group_approved_member_map
as select gm.group_id, gm.member_id, gm.rel_id, gm.container_id, gm.rel_type
   from group_member_map gm, membership_rels mr
   where gm.rel_id = mr.rel_id
   and mr.member_state = 'approved';

create or replace view group_distinct_member_map
as select distinct group_id, member_id
   from group_approved_member_map;

-- some more views, like party_member_map and party_approved_member_map,
-- are created in rel-segments-create.sql

-- Just in case someone is still querying the group_component_index and
-- group_member_index directly, lets make them views.
create or replace view group_component_index as select * from group_component_map;
create or replace view group_member_index as select * from group_member_map;


---------------
-- FUNCTIONS --
---------------

create or replace function group_contains_p (group_id integer, component_id integer, rel_id integer default null) return char
is
begin
  if group_id = component_id then
    return 't';
  else
    if rel_id is null then
      for map in (select *
                  from group_component_map
                  where component_id = group_contains_p.component_id
                  and group_id = container_id) loop
        if group_contains_p(group_id, map.group_id) = 't' then
          return 't';
        end if;
      end loop;
    else
      for map in (select *
                  from group_component_map
                  where component_id = group_contains_p.component_id
                  and rel_id = group_contains_p.rel_id
                  and group_id = container_id) loop
        if group_contains_p(group_id, map.group_id) = 't' then
          return 't';
        end if;
      end loop;
    end if;

    return 'f';
  end if;
end;
/
show errors


------------------------
-- TEMPORARY TRIGGERS --
------------------------

-- These triggers are used to prevent people from defining membership
-- or composition relations until the groups-triggers-create file is
-- sourced. That file will replace these triggers with triggers
-- that actually do useful work

create or replace trigger membership_rels_in_tr
after insert on membership_rels
declare
begin
  raise_application_error(-20000,'Insert to membership rels not yet supported');
end;
/
show errors


create or replace trigger composition_rels_in_tr
after insert on composition_rels
declare
begin
  raise_application_error(-20000,'Insert to membership rels not yet supported');
end;
/
show errors


---------------------------------------------
-- POPULATE DATA FOR PERMISSIBLE REL TYPES --
---------------------------------------------

-- define standard types for groups of type 'group'
insert into group_type_rels 
(group_rel_type_id, rel_type, group_type)
values
(acs_object_id_seq.nextval, 'membership_rel', 'group');

insert into group_type_rels 
(group_rel_type_id, rel_type, group_type)
values
(acs_object_id_seq.nextval, 'composition_rel', 'group');


--------------
-- PACKAGES --
--------------

create or replace package composition_rel
as

  function new (
    rel_id              in composition_rels.rel_id%TYPE default null,
    rel_type            in acs_rels.rel_type%TYPE default 'composition_rel',
    object_id_one       in acs_rels.object_id_one%TYPE,
    object_id_two       in acs_rels.object_id_two%TYPE,
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return composition_rels.rel_id%TYPE;

  procedure del (
    rel_id      in composition_rels.rel_id%TYPE
  );

  function check_path_exists_p (
    component_id        in groups.group_id%TYPE,
    container_id        in groups.group_id%TYPE
  ) return char;

  function check_representation (
    rel_id      in composition_rels.rel_id%TYPE
  ) return char;

end composition_rel;
/
show errors


create or replace package membership_rel
as

  function new (
    rel_id              in membership_rels.rel_id%TYPE default null,
    rel_type            in acs_rels.rel_type%TYPE default 'membership_rel',
    object_id_one       in acs_rels.object_id_one%TYPE,
    object_id_two       in acs_rels.object_id_two%TYPE,
    member_state        in membership_rels.member_state%TYPE default 'approved',
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return membership_rels.rel_id%TYPE;

  procedure ban (
    rel_id      in membership_rels.rel_id%TYPE
  );

  procedure approve (
    rel_id      in membership_rels.rel_id%TYPE
  );

  procedure merge (
    rel_id      in membership_rels.rel_id%TYPE
  );

  procedure reject (
    rel_id      in membership_rels.rel_id%TYPE
  );

  procedure unapprove (
    rel_id      in membership_rels.rel_id%TYPE
  );

  procedure deleted (
    rel_id      in membership_rels.rel_id%TYPE
  );

  procedure del (
    rel_id      in membership_rels.rel_id%TYPE
  );

  function check_representation (
    rel_id      in membership_rels.rel_id%TYPE
  ) return char;

end membership_rel;
/
show errors


create or replace package admin_rel
as

  function new (
    rel_id              in admin_rels.rel_id%TYPE default null,
    rel_type            in acs_rels.rel_type%TYPE default 'admin_rel',
    object_id_one       in acs_rels.object_id_one%TYPE,
    object_id_two       in acs_rels.object_id_two%TYPE,
    member_state        in membership_rels.member_state%TYPE default 'approved',
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return admin_rels.rel_id%TYPE;

  procedure del (
    rel_id      in admin_rels.rel_id%TYPE
  );

end admin_rel;
/
show errors


create or replace package acs_group
is
 function new (
  group_id              in groups.group_id%TYPE default null,
  object_type           in acs_objects.object_type%TYPE
                           default 'group',
  creation_date         in acs_objects.creation_date%TYPE
                           default sysdate,
  creation_user         in acs_objects.creation_user%TYPE
                           default null,
  creation_ip           in acs_objects.creation_ip%TYPE default null,
  email                 in parties.email%TYPE default null,
  url                   in parties.url%TYPE default null,
  group_name            in groups.group_name%TYPE,
  join_policy           in groups.join_policy%TYPE default null,
  context_id	in acs_objects.context_id%TYPE default null
 ) return groups.group_id%TYPE;

 procedure del (
   group_id     in groups.group_id%TYPE
 );

 function name (
  group_id      in groups.group_id%TYPE
 ) return varchar2;

 function member_p (
  party_id      in parties.party_id%TYPE,
  group_id	in groups.group_id%TYPE,
  cascade_membership char	
 ) return char;

 function check_representation (
  group_id      in groups.group_id%TYPE
 ) return char;

end acs_group;
/
show errors

