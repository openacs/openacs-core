--
-- packages/acs-kernel/sql/rel-segments-create.sql
--
-- @author Oumi Mehrotra oumi@arsdigita.com
-- @creation-date 2000-11-22
-- @cvs-id $Id$

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

-- WARNING!
-- Relational segments is a new and experimental concept.  The API may
-- change in the future, particularly the functions marked "EXPERIMENTAL".
-- 

CREATE OR REPLACE FUNCTION inline_0 () RETURNS integer AS $$
BEGIN
 --
 -- Relational Segment: a dynamically derived set of parties, defined
 --                     in terms of a particular type of membership or 
 --                     composition to a particular group.
 --
 PERFORM acs_object_type__create_type (
   'rel_segment',
   '#acs-kernel.lt_Relational_Party_Segm#',
   '#acs-kernel.lt_Relational_Party_Segm_1#',
   'party',
   'rel_segments',
   'segment_id',
   'rel_segment',
   'f',
   null,
   'rel_segment__name'
   );

  return 0;
END;
$$ LANGUAGE plpgsql;

select inline_0 ();

drop function inline_0 ();


-- show errors


-- Note that we do not use on delete cascade on the group_id or
-- rel_type column because rel_segments are acs_objects. On delete
-- cascade only deletes the corresponding row in this table, not all
-- the rows up the type hierarchy. Thus, rel segments must be deleted
-- using rel_segment.delete before dropping a relationship type.

create table rel_segments (
        segment_id      integer not null
                        constraint rel_segments_segment_id_fk
                        references parties (party_id)
                        constraint rel_segments_segment_id_pk primary key,
        segment_name    varchar(230) not null,
        group_id        integer not null
                        constraint rel_segments_group_id_fk
                        references groups (group_id)
                        on delete cascade,
        rel_type        varchar(100) not null
                        constraint rel_segments_rel_type_fk
                        references acs_rel_types (rel_type)
                        on delete cascade,
        constraint rel_segments_grp_rel_type_un unique(group_id, rel_type)
);

-- rel_type has a foreign key reference - create an index
create index rel_segments_rel_type_idx on rel_segments(rel_type);

comment on table rel_segments is '
  Defines relational segments. Each relational segment is a pair of
  <code>group_id</code> / <code>rel_type</code>, or, in english, the
  parties that have a relation of type rel_type to group_id.
';

comment on column rel_segments.segment_name is '
  The user-entered name of the relational segment.
';

comment on column rel_segments.group_id is '
  The group for which this segment was created.
';

comment on column rel_segments.rel_type is '
  The relationship type used to define elements in this segment.
';


-- create pl/sql package rel_segment

-----------
-- Views --
-----------

create view rel_segment_party_map
as select rs.segment_id, gem.element_id as party_id, gem.rel_id, gem.rel_type, 
          gem.group_id, gem.container_id, gem.ancestor_rel_type
   from rel_segments rs, group_element_map gem, acs_object_types ot1, acs_object_types ot2
   where gem.group_id = rs.group_id
     and ot1.object_type = gem.rel_type
     and ot2.object_type = rs.rel_type
     and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey);

create view rel_segment_distinct_party_map
as select distinct segment_id, party_id, ancestor_rel_type
   from rel_segment_party_map;

create view rel_segment_member_map
as select segment_id, party_id as member_id, rel_id, rel_type, 
          group_id, container_id
   from rel_segment_party_map
   where ancestor_rel_type = 'membership_rel';

create view rel_seg_approved_member_map
as select rs.segment_id, gem.element_id as member_id, gem.rel_id, 
          gem.rel_type, gem.group_id, gem.container_id
    from membership_rels mr, group_element_map gem, rel_segments rs,
         acs_object_types ot1, acs_object_types ot2
   where rs.group_id = gem.group_id 
     and rs.rel_type = ot2.object_type
     and ot1.object_type = gem.rel_type 
     and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
     and mr.rel_id = gem.rel_id and mr.member_state = 'approved';

create view rel_seg_distinct_member_map
as select distinct segment_id, member_id
   from rel_seg_approved_member_map;

-- Though for permission checking we only really need to map parties to
-- member users, the old view included identity entries for all parties
-- in the system.  It doesn't cost all that much to maintain the extra
-- rows so we will, just in case some overly clever programmer out there
-- depends on it.

-- This represents a large amount of redundant data which is separately
-- stored in the group_element_index table.   We might want to clean this
-- up in the future but time constraints on 4.6.1 require I keep this 
-- relatively simple.  Implementing a real "subgroup_rel" would help a
-- lot by in itself reducing the number of redundant rows in the two
-- tables.

-- DRB: Unfortunately visibility semantics in PostgreSQL are very different
-- than in Oracle.  This makes it impossible to remove the duplicate
-- rows by maintaining a count column as I've done in the Oracle version
-- without requiring application code to issue explicit "lock table in
-- exclusive mode" statements.  This would kill abstraction and be very
-- error prone.  The PL/pgSQL procs can issue the locks but unfortunately
-- statements within such procs don't generate a new snapshot when executed
-- but rather work within the context of the caller.  This means locks within
-- a PL/pgSQL are too late to be of use.  Such code works perfectly in Oracle.

-- Maybe people who buy Oracle aren't as dumb as you thought!

create table party_approved_member_map (
    party_id        integer
                    constraint party_member_party_nn
                    not null
                    constraint party_member_party_fk
                    references parties
                    on delete cascade,
    member_id       integer
                    constraint party_member_member_nn
                    not null
                    constraint party_member_member_fk
                    references parties
                    on delete cascade,
    originating_rel_id integer
                    constraint party_member_rel_id_fk
                    references acs_rels
                    on delete cascade,
    constraint party_approved_member_map_pk
    primary key (party_id, member_id, originating_rel_id)
);

-- Need this to speed referential integrity 
create index party_member_member_idx on party_approved_member_map(member_id);
create index party_member_party_idx on party_approved_member_map(party_id);
create index party_member_originating_idx on party_approved_member_map(originating_rel_id);

-- Helper functions to maintain the materialized party_approved_member_map. 





select define_function_args('party_approved_member__add_one','party_id,member_id,rel_id');

--
-- procedure party_approved_member__add_one/3
--
CREATE OR REPLACE FUNCTION party_approved_member__add_one(
   p_party_id integer,
   p_member_id integer,
   p_rel_id integer
) RETURNS integer AS $$
DECLARE
BEGIN

  insert into party_approved_member_map
    (party_id, member_id, originating_rel_id)
  values
    (p_party_id, p_member_id, p_rel_id);

  return 1;

END;
$$ LANGUAGE plpgsql;



select define_function_args('party_approved_member__add','party_id,member_id,rel_id,rel_type');

--
-- procedure party_approved_member__add/4
--
CREATE OR REPLACE FUNCTION party_approved_member__add(
   p_party_id integer,
   p_member_id integer,
   p_rel_id integer,
   p_rel_type varchar
) RETURNS integer AS $$
DECLARE
  v_segments record;
BEGIN

  perform party_approved_member__add_one(p_party_id, p_member_id, p_rel_id);

  -- if the relation type is mapped to relational segments map them too

  for v_segments in select segment_id
                  from rel_segments s, acs_object_types ot1, acs_object_types ot2
                  where 
                    ot1.object_type = p_rel_type
                    and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
                    and s.rel_type = ot2.object_type
                    and s.group_id = p_party_id
  loop
    perform party_approved_member__add_one(v_segments.segment_id, p_member_id, p_rel_id);
  end loop;

  return 1;

END;
$$ LANGUAGE plpgsql;



select define_function_args('party_approved_member__remove_one','party_id,member_id,rel_id');

--
-- procedure party_approved_member__remove_one/3
--
CREATE OR REPLACE FUNCTION party_approved_member__remove_one(
   p_party_id integer,
   p_member_id integer,
   p_rel_id integer
) RETURNS integer AS $$
DECLARE
BEGIN

  delete from party_approved_member_map
  where party_id = p_party_id
    and member_id = p_member_id
    and originating_rel_id = p_rel_id;

  return 1;

END;
$$ LANGUAGE plpgsql;




select define_function_args('party_approved_member__remove','party_id,member_id,rel_id,rel_type');

--
-- procedure party_approved_member__remove/4
--
CREATE OR REPLACE FUNCTION party_approved_member__remove(
   p_party_id integer,
   p_member_id integer,
   p_rel_id integer,
   p_rel_type varchar
) RETURNS integer AS $$
DECLARE
  v_segments record;
BEGIN

  perform party_approved_member__remove_one(p_party_id, p_member_id, p_rel_id);

  -- if the relation type is mapped to relational segments unmap them too

  for v_segments in select segment_id
                  from rel_segments s, acs_object_types ot1, acs_object_types ot2
                  where 
                    ot1.object_type = p_rel_type
                    and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
                    and s.rel_type = ot2.object_type
                    and s.group_id = p_party_id
  loop
    perform party_approved_member__remove_one(v_segments.segment_id, p_member_id, p_rel_id);
  end loop;

  return 1;

END;
$$ LANGUAGE plpgsql;


-- Triggers to maintain party_approved_member_map when parties are created or
-- destroyed.  These don't call the above helper functions because we're just
-- creating the identity row for the party.

CREATE OR REPLACE FUNCTION parties_in_tr () RETURNS trigger AS $$
BEGIN

  insert into party_approved_member_map
    (party_id, member_id, originating_rel_id)
  values
    (new.party_id, new.party_id, -10);

  return new;

END;
$$ LANGUAGE plpgsql;

 create trigger parties_in_tr after insert on parties
 for each row execute procedure parties_in_tr ();

CREATE OR REPLACE FUNCTION parties_del_tr () RETURNS trigger AS $$
BEGIN

  delete from party_approved_member_map
  where party_id = old.party_id
    and member_id = old.party_id;

  return old;

END;
$$ LANGUAGE plpgsql;

create trigger parties_del_tr before delete on parties
for each row execute procedure parties_del_tr ();

-- Triggers to maintain party_approved_member_map when relational segments are
-- created or destroyed.   We only remove the (segment_id, member_id) rows as
-- removing the relational segment itself does not remove members from the
-- group with that rel_type.  This was intentional on the part of the aD folks
-- who added relational segments to ACS 4.2.

CREATE OR REPLACE FUNCTION rel_segments_in_tr () RETURNS trigger AS $$
BEGIN

  insert into party_approved_member_map
    (party_id, member_id, originating_rel_id)
  select new.segment_id, element_id, rel_id
    from group_element_index
    where group_id = new.group_id
      and rel_type = new.rel_type;

  return new;

END;
$$ LANGUAGE plpgsql;

create trigger rel_segments_in_tr before insert on rel_segments
for each row execute procedure rel_segments_in_tr ();

CREATE OR REPLACE FUNCTION rel_segments_del_tr () RETURNS trigger AS $$
BEGIN

  delete from party_approved_member_map
  where party_id = old.segment_id
    and member_id in (select element_id
                      from group_element_index
                      where group_id = old.group_id
                        and rel_type = old.rel_type);

  return old;

END;
$$ LANGUAGE plpgsql;

create trigger rel_segments_del_tr before delete on rel_segments
for each row execute procedure rel_segments_del_tr ();

-- View: rel_segment_group_rel_type_map
--
-- Result Set: the set of triples (:segment_id, :group_id, :rel_type) such that
--
--             IF a party were to be in :group_id 
--                through a relation of type :rel_type,
--             THEN the party would necessarily be in segment :segemnt_id.    
 
create view rel_segment_group_rel_type_map as
select s.segment_id, 
       gcm.component_id as group_id, 
       acs_rel_types.rel_type as rel_type
from rel_segments s,
     (select group_id, component_id
      from group_component_map
      UNION ALL
      select group_id, group_id as component_id
      from groups) gcm,
     acs_rel_types,
     acs_object_types ot1, acs_object_types ot2
where s.group_id = gcm.group_id
  and s.rel_type = ot2.object_type
  and ot1.object_type = acs_rel_types.rel_type
  and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey);
 
