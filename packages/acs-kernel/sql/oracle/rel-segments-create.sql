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

begin
 --
 -- Relational Segment: a dynamically derived set of parties, defined
 --                     in terms of a particular type of membership or 
 --                     composition to a particular group.
 --
 acs_object_type.create_type (
   supertype => 'party',
   object_type => 'rel_segment',
   pretty_name => 'Relational Party Segment',
   pretty_plural => 'Relational Party Segments',
   table_name => 'rel_segments',
   id_column => 'segment_id',
   package_name => 'rel_segment',
   name_method => 'rel_segment.name'
 );

end;
/
show errors


-- Note that we do not use on delete cascade on the group_id or
-- rel_type column because rel_segments are acs_objects. On delete
-- cascade only deletes the corresponding row in this table, not all
-- the rows up the type hierarchy. Thus, rel segments must be deleted
-- using rel_segment.delete before dropping a relationship type.

create table rel_segments (
        segment_id      constraint rel_segments_segment_id_nn not null
                        constraint rel_segments_segment_id_fk
                        references parties (party_id)
                        constraint rel_segments_segment_id_pk primary key,
        segment_name    varchar2(230) 
			constraint rel_segments_segment_name_nn not null,
        group_id        constraint rel_segments_group_id_nn not null
                        constraint rel_segments_group_id_fk
                        references groups (group_id)
                        on delete cascade,
        rel_type        constraint rel_segments_rel_type_nn not null
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

create or replace package rel_segment
is
 function new (
  --/** Creates a new relational segment
  -- 
  --    @author Oumi Mehrotra (oumi@arsdigita.com)
  --    @creation-date 12/2000
  -- 
  --*/
  segment_id            in rel_segments.segment_id%TYPE default null,
  object_type           in acs_objects.object_type%TYPE
                           default 'rel_segment',
  creation_date         in acs_objects.creation_date%TYPE
                           default sysdate,
  creation_user         in acs_objects.creation_user%TYPE
                           default null,
  creation_ip           in acs_objects.creation_ip%TYPE default null,
  email                 in parties.email%TYPE default null,
  url                   in parties.url%TYPE default null,
  segment_name          in rel_segments.segment_name%TYPE,
  group_id              in rel_segments.group_id%TYPE,
  rel_type              in rel_segments.rel_type%TYPE,
  context_id	in acs_objects.context_id%TYPE default null
 ) return rel_segments.segment_id%TYPE;

 procedure del (
    --/** Deletes a relational segment
    -- 
    --    @author Oumi Mehrotra (oumi@arsdigita.com)
    --    @creation-date 12/2000
    -- 
    --*/
   segment_id     in rel_segments.segment_id%TYPE
 );

 function name (
  segment_id      in rel_segments.segment_id%TYPE
 ) return rel_segments.segment_name%TYPE;

 function get (
    --/** EXPERIMENTAL / UNSTABLE -- use at your own risk
    --    Get the id of a segment given a group_id and rel_type.
    --    This depends on the uniqueness of group_id,rel_type.  We
    --    might remove the unique constraint in the future, in which
    --    case we would also probably remove this function.
    --
    --    @author Oumi Mehrotra (oumi@arsdigita.com)
    --    @creation-date 12/2000
    --
    --*/

   group_id       in rel_segments.group_id%TYPE,
   rel_type       in rel_segments.rel_type%TYPE
 ) return rel_segments.segment_id%TYPE;

 function get_or_new (
    --/** EXPERIMENTAL / UNSTABLE -- use at your own risk
    --
    --    This function simplifies the use of segments a little by letting
    --    you not have to worry about creating and initializing segments.
    --    If the segment you're interested in exists, this function
    --    returns its segment_id.
    --    If the segment you're interested in doesn't exist, this function
    --    does a pretty minimal amount of initialization for the segment
    --    and returns a new segment_id.
    --
    --    @author Oumi Mehrotra (oumi@arsdigita.com)
    --    @creation-date 12/2000
    --
    --*/
   group_id       in rel_segments.group_id%TYPE,
   rel_type       in rel_segments.rel_type%TYPE,
   segment_name   in rel_segments.segment_name%TYPE
                  default null
 ) return rel_segments.segment_id%TYPE;

end rel_segment;
/
show errors


-----------
-- Views --
-----------

create or replace view rel_segment_party_map
as select rs.segment_id, gem.element_id as party_id, gem.rel_id, gem.rel_type, 
          gem.group_id, gem.container_id, gem.ancestor_rel_type
   from rel_segments rs, 
        group_element_map gem 
   where gem.group_id = rs.group_id
     and rs.rel_type in (select object_type 
                         from acs_object_types 
                         start with object_type = gem.rel_type 
                         connect by prior supertype = object_type);


create or replace view rel_segment_distinct_party_map
as select distinct segment_id, party_id, ancestor_rel_type
   from rel_segment_party_map;

create or replace view rel_segment_member_map
as select segment_id, party_id as member_id, rel_id, rel_type, 
          group_id, container_id
   from rel_segment_party_map
   where ancestor_rel_type = 'membership_rel';

create or replace view rel_seg_approved_member_map
as select /*+ ordered */ 
          rs.segment_id, gem.element_id as member_id, gem.rel_id, gem.rel_type, 
          gem.group_id, gem.container_id
    from membership_rels mr, group_element_map gem, rel_segments rs
   where rs.group_id = gem.group_id 
     and rs.rel_type in (select object_type 
                         from acs_object_types 
                         start with object_type = gem.rel_type 
                         connect by prior supertype = object_type)
     and mr.rel_id = gem.rel_id and mr.member_state = 'approved';

create or replace view rel_seg_distinct_member_map
as select distinct segment_id, member_id
   from rel_seg_approved_member_map;

-- The party_approved_member_map table maps all parties to all their
-- members.  It's here rather in a logical place for historical reasons.

-- The count column is needed because composition_rels lead to a lot of
-- redundant data in the group element map (i.e. you can belong to the
-- registered users group an infinite number of times, strange concept)

-- (it is "cnt" rather than "count" because Oracle confuses it with the
-- "count()" aggregate in some contexts)

-- Though for permission checking we only really need to map parties to
-- member users, the old view included identity entries for all parties
-- in the system.  It doesn't cost all that much to maintain the extra
-- rows so we will, just in case some overly clever programmer out there
-- depends on it.

create table party_approved_member_map (
    party_id        integer
                    constraint party_member_party_fk
                    references parties,
    member_id       integer
                    constraint party_member_member_fk
                    references parties,
    cnt             integer,
    constraint party_approved_member_map_pk
    primary key (party_id, member_id)
);

-- Need this to speed referential integrity 
create index party_member_member_idx on party_approved_member_map(member_id);

-- Triggers to maintain party_approved_member_map when parties are create or replaced or
-- destroyed.

create or replace trigger parties_in_tr after insert on parties
for each row 
begin
  insert into party_approved_member_map
    (party_id, member_id, cnt)
  values
    (:new.party_id, :new.party_id, 1);
end parties_in_tr;
/
show errors;

create or replace trigger parties_del_tr before delete on parties
for each row
begin
  delete from party_approved_member_map
  where party_id = :old.party_id
    and member_id = :old.party_id;
end parties_del_tr;
/
show errors;

-- Triggers to maintain party_approved_member_map when relational segments are
-- create or replaced or destroyed.   We only remove the (segment_id, member_id) rows as
-- removing the relational segment itself does not remove members from the
-- group with that rel_type.  This was intentional on the part of the aD folks
-- who added relational segments to ACS 4.2.

create or replace trigger rel_segments_in_tr before insert on rel_segments
for each row
begin
  insert into party_approved_member_map
    (party_id, member_id, cnt)
  select :new.segment_id, element_id, 1
    from group_element_index
    where group_id = :new.group_id
      and rel_type = :new.rel_type;
end rel_segments_in_tr;
/
show errors;

create or replace trigger rel_segments_del_tr before delete on rel_segments
for each row
begin
  delete from party_approved_member_map
  where party_id = :old.segment_id
    and member_id in (select element_id
                      from group_element_index
                      where group_id = :old.group_id
                        and rel_type = :old.rel_type);
end parties_del_tr;
/
show errors;

-- DRB: Helper functions to maintain the materialized party_approved_member_map.  The counting crap
-- has to do with the fact that composition rels create duplicate rows in groups.

create or replace package party_approved_member is

  procedure add_one(
    p_party_id in parties.party_id%TYPE,
    p_member_id in parties.party_id%TYPE
  );

  procedure add(
    p_party_id in parties.party_id%TYPE,
    p_member_id in parties.party_id%TYPE,
    p_rel_type in acs_rels.rel_type%TYPE
  );

  procedure remove_one (
    p_party_id in parties.party_id%TYPE,
    p_member_id in parties.party_id%TYPE
  );

  procedure remove (
    p_party_id in parties.party_id%TYPE,
    p_member_id in parties.party_id%TYPE,
    p_rel_type in acs_rels.rel_type%TYPE
  );

end party_approved_member;
/
show errors;

create or replace package body party_approved_member is

  procedure add_one(
    p_party_id in parties.party_id%TYPE,
    p_member_id in parties.party_id%TYPE
  )
  is
  begin

    insert into party_approved_member_map
      (party_id, member_id, cnt)
    values
      (p_party_id, p_member_id, 1);

    exception when dup_val_on_index then
      update party_approved_member_map
      set cnt = cnt + 1
      where party_id = p_party_id
        and member_id = p_member_id;

  end add_one;

  procedure add(
    p_party_id in parties.party_id%TYPE,
    p_member_id in parties.party_id%TYPE,
    p_rel_type in acs_rels.rel_type%TYPE
  )
  is
  begin

    add_one(p_party_id, p_member_id);

    -- if the relation type is mapped to a relational segment map that too

    for v_segments in (select segment_id
                       from rel_segments
                       where group_id = p_party_id
                         and rel_type in (select object_type
                                          from acs_object_types
                                          start with object_type = p_rel_type
                                          connect by prior supertype = object_type))
    loop
      add_one(v_segments.segment_id, p_member_id);
    end loop;

  end add;

  procedure remove_one (
    p_party_id in parties.party_id%TYPE,
    p_member_id in parties.party_id%TYPE
  )
  is
  begin

    update party_approved_member_map
    set cnt = cnt - 1
    where party_id = p_party_id
      and member_id = p_member_id;

    delete from party_approved_member_map
    where party_id = p_party_id
      and member_id = p_member_id
      and cnt = 0;

  end remove_one;

  procedure remove (
    p_party_id in parties.party_id%TYPE,
    p_member_id in parties.party_id%TYPE,
    p_rel_type in acs_rels.rel_type%TYPE
  )
  is
  begin

    remove_one(p_party_id, p_member_id);

    -- if the relation type is mapped to a relational segment unmap that too

    for v_segments in (select segment_id
                       from rel_segments
                       where group_id = p_party_id
                         and rel_type in (select object_type
                                          from acs_object_types
                                          start with object_type = p_rel_type
                                          connect by prior supertype = object_type))
    loop
      remove_one(v_segments.segment_id, p_member_id);
    end loop;

  end remove;

end party_approved_member;
/
show errors;

-- View: rel_segment_group_rel_type_map
--
-- Result Set: the set of triples (:segment_id, :group_id, :rel_type) such that
--
--             IF a party were to be in :group_id 
--                through a relation of type :rel_type,
--             THEN the party would necessarily be in segment :segemnt_id.    
--
--
create or replace view rel_segment_group_rel_type_map as
select s.segment_id, 
       gcm.component_id as group_id, 
       acs_rel_types.rel_type as rel_type
from rel_segments s,
     (select group_id, component_id
      from group_component_map
      UNION ALL
      select group_id, group_id as component_id
      from groups) gcm,
     acs_rel_types
where s.group_id = gcm.group_id
  and s.rel_type in (select object_type from acs_object_types
                     start with object_type = acs_rel_types.rel_type
                     connect by prior supertype = object_type);

