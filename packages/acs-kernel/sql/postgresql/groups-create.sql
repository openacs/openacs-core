--
-- packages/acs-kernel/sql/groups-create.sql
--
-- @author rhs@mit.edu
-- @creation-date 2000-08-22
-- @cvs-id groups-create.sql,v 1.16.2.3 2001/01/19 00:50:37 mbryzek Exp
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
        rel_id          integer constraint composition_rel_rel_id_fk
                        references acs_rels (rel_id)
                        constraint composition_rel_rel_id_pk
                        primary key
);

create table membership_rels (
        rel_id          integer constraint membership_rel_rel_id_fk
                        references acs_rels (rel_id)
                        constraint membership_rel_rel_id_pk
                        primary key,
        -- null means waiting for admin approval
        member_state    varchar(20) constraint membership_rel_mem_ck
                        check (member_state in ('approved', 'needs approval',
                                              'banned', 'rejected', 'deleted'))
);

create table admin_rels (
        rel_id          integer constraint admin_rel_rel_id_fk
                        references membership_rels (rel_id)
                        constraint admin_rel_rel_id_pk
                        primary key
);

create function inline_0 ()
returns integer as '
declare
  attr_id acs_attributes.attribute_id%TYPE;
begin
 --
 -- Group: a composite party
 --
 attr_id := acs_object_type__create_type (
   ''group'',
   ''Group'',
   ''Groups'',
   ''party'',
   ''groups'',
   ''group_id'',
   ''acs_group'',
   ''f'',
   ''group_types'',
   ''acs_group.name''
   );

 attr_id := acs_attribute__create_attribute (
	''group'',
	''group_name'',
	''string'',
	''Group name'',
	''Group names'',
	null,
	null,
	null,
	1,
	1,
	null,
	''type_specific'',
	''f''
	);

 --
 -- Composition Relationship
 --
 attr_id := acs_rel_type__create_role (''composite'', ''Composite'', ''Composites'');
 attr_id := acs_rel_type__create_role (''component'', ''Component'', ''Components'');

 attr_id := acs_rel_type__create_type (
   ''composition_rel'',
   ''Composition Relation'',
   ''Composition Relationships'',
   ''relationship'',
   ''composition_rels'',
   ''rel_id'',
   ''composition_rel'',
   ''group'',
   ''composite'',
    0, 
    null,
   ''group'',
   ''component'',
   0,
   null
   );


 --
 -- Membership Relationship
 --
 attr_id := acs_rel_type__create_role (''member'', ''#acs-kernel.member_role_pretty_name#'', ''#acs-kernel.member_role_pretty_plural#'');

 attr_id := acs_rel_type__create_type (
   ''membership_rel'',                 -- rel_type
   ''Membership Relation'',            -- pretty_name
   ''Membership Relationships'',       -- pretty_plural
   ''relationship'',                   -- supertype
   ''membership_rels'',                -- table_name
   ''rel_id'',                         -- id_column
   ''membership_rel'',                 -- package_name
   ''group'',                          -- object_type_one
   null,                               -- role_one
   0,                                  -- min_n_rels_one
   null,                               -- max_n_rels_one
   ''person'',                         -- object_type_two
   ''member'',                         -- role_two
   0,                                  -- min_n_rels_two
   null                                -- max_n_rels_two
   );

 --
 -- Administrator Relationship
 --
 attr_id := acs_rel_type__create_role (''admin'', ''Administrator'', ''Administrators'');

 attr_id := acs_rel_type__create_type (
   ''admin_rel'',                      -- rel_type
   ''Administrator Relation'',         -- pretty_name
   ''Administrator Relationships'',    -- pretty_plural
   ''membership_rel'',                 -- supertype
   ''admin_rels'',                     -- table_name
   ''rel_id'',                         -- id_column
   ''admin_rel'',                      -- package_name
   ''group'',                          -- object_type_one
   null,                               -- role_one
   0,                                  -- min_n_rels_one
   null,                               -- max_n_rels_one
   ''person'',                         -- object_type_two
   ''admin'',                          -- role_two
   0,                                  -- min_n_rels_two
   null                                -- max_n_rels_two   
   );

  return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();


-- show errors

create table group_types (
        group_type              varchar(400) not null
                                constraint group_types_pk primary key
                                constraint group_types_obj_type_fk
                                references acs_object_types (object_type),
	-- commented out by Ben (OpenACS), to make it in sync with Oracle version..
	--        approval_policy         varchar(30) not null,
        default_join_policy     varchar(30) default 'open' not null
                                constraint group_types_join_policy_ck
                                check (default_join_policy in 
                                ('open', 'needs approval', 'closed'))
);

comment on table group_types is '
 This table holds additional knowledge level attributes for the
 group type and its subtypes.
';

create table groups (
        group_id        integer not null
                        constraint groups_group_id_fk
                        references parties (party_id)
                        constraint groups_pk primary key,
        group_name      varchar(1000) not null,
        join_policy     varchar(30) default 'open' not null
                        constraint groups_join_policy_ck
                        check (join_policy in 
                               ('open', 'needs approval', 'closed'))
);



create table group_type_rels (
       group_rel_type_id      integer constraint gtr_group_rel_type_id_pk primary key,
       rel_type		      varchar(100) not null 
                              constraint gtr_rel_type_fk
                              references acs_rel_types (rel_type)
                              on delete cascade,
       group_type	      varchar(100) not null 
                              constraint gtr_group_type_fk
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
       rel_type		      varchar(100) not null 
                              constraint group_rels_rel_type_fk
                              references acs_rel_types (rel_type)
                              on delete cascade,
       group_id	              integer not null 
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

-- oumi@arsdigita.com - Jan 04, 2001 - 
-- Combined group_member_index and group_element_index into one table. This
-- allows for simpler queries about party aggregation, especially for 
-- relational segments (see rel-segments-create.sql).

create table group_element_index (
	group_id	integer not null
			constraint group_element_index_grp_id_fk
			references groups (group_id),
	element_id	integer not null
			constraint group_element_index_elem_id_fk
			references parties (party_id),
	rel_id		integer not null
			constraint group_element_index_rel_id_fk
			references acs_rels (rel_id),
	container_id	integer not null
			constraint group_element_index_cont_id_fk
			references groups (group_id),
        rel_type        varchar(100) not null
                        constraint group_elem_index_rel_type_fk
                        references acs_rel_types (rel_type),
        ancestor_rel_type varchar(100) not null
                        constraint grp_el_idx_ancstr_rel_type_ck
                        check (ancestor_rel_type in ('composition_rel','membership_rel')),
	constraint group_element_index_pk
	primary key (element_id, group_id, rel_id)
);

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

create view group_element_map
as select group_id, element_id, rel_id, container_id, 
          rel_type, ancestor_rel_type
   from group_element_index;

create view group_component_map
as select group_id, element_id as component_id, rel_id, container_id, rel_type
   from group_element_map
   where ancestor_rel_type='composition_rel';

create view group_member_map
as select group_id, element_id as member_id, rel_id, container_id, rel_type
   from group_element_map
   where ancestor_rel_type='membership_rel';

create view group_approved_member_map
as select gm.group_id, gm.member_id, gm.rel_id, gm.container_id, gm.rel_type
   from group_member_map gm, membership_rels mr
   where gm.rel_id = mr.rel_id
   and mr.member_state = 'approved';

create view group_distinct_member_map
as select distinct group_id, member_id
   from group_approved_member_map;

-- some more views, like party_memeber_map and party_approved_member_map,
-- are created in rel-segments-create.sql

-- Just in case someone is still querying the group_component_index and
-- group_member_index directly, lets make them views.
create view group_component_index as select * from group_component_map;
create view group_member_index as select * from group_member_map;


---------------
-- FUNCTIONS --
---------------
-- drop function group_contains_p (integer, integer, integer);
create function group_contains_p (integer, integer, integer) 
returns boolean as '
declare 
        group_contains_p__group_id        alias for $1;
        group_contains_p__component_id    alias for $2;
        group_contains_p__rel_id          alias for $3;
        map                               record;
begin
  if group_contains_p__group_id = group_contains_p__component_id then
    return ''t'';
  else
    if group_contains_p__rel_id is null then
      for map in  select *
                  from group_component_map
                  where component_id = group_contains_p__component_id
                  and group_id = container_id 
      LOOP
        if group_contains_p(group_contains_p__group_id, map.group_id, null) = ''t'' then
          return ''t'';
        end if;
      end loop;
    else
      for map in  select *
                  from group_component_map
                  where component_id = group_contains_p__component_id
                  and rel_id = group_contains_p__rel_id
                  and group_id = container_id 
      LOOP
        if group_contains_p(group_contains_p__group_id, map.group_id, null) = ''t'' then
          return ''t'';
        end if;
      end loop;
    end if;
    return ''f'';
  end if;
end;' language 'plpgsql' stable;



-- show errors


------------------------
-- TEMPORARY TRIGGERS --
------------------------

-- These triggers are used to prevent people from defining membership
-- or composition relations until the groups-triggers-create file is
-- sourced. That file will replace these triggers with triggers
-- that actually do useful work

create function membership_rels_in_tr () returns opaque as '
declare
begin
  raise EXCEPTION ''-20000: Insert to membership rels not yet supported'';

  return new;

end;' language 'plpgsql';

create trigger  membership_rels_in_tr after insert  on membership_rels
for each row  execute procedure membership_rels_in_tr ();

-- show errors


create function composition_rels_in_tr () returns opaque as '
declare
begin
  raise EXCEPTION ''-20000: Insert to composition rels not yet supported'';

  return new;

end;' language 'plpgsql';

create trigger composition_rels_in_tr  after insert on composition_rels
for each row  execute procedure  composition_rels_in_tr();

-- show errors


---------------------------------------------
-- POPULATE DATA FOR PERMISSABLE REL TYPES --
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
