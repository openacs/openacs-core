--
-- packages/acs-kernel/sql/rel-segments-create.sql
--
-- @author Oumi Mehrotra oumi@arsdigita.com
-- @creation-date 2000-11-22
-- @cvs-id rel-segments-create.sql,v 1.1.4.3 2001/01/16 18:54:05 oumi Exp

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

-- WARNING!
-- Relational segments is a new and experimental concept.  The API may
-- change in the future, particularly the functions marked "EXPERIMENTAL".
-- 

create function inline_0 ()
returns integer as '
begin
 --
 -- Relational Segment: a dynamically derived set of parties, defined
 --                     in terms of a particular type of membership or 
 --                     composition to a particular group.
 --
 PERFORM acs_object_type__create_type (
   ''rel_segment'',
   ''Relational Party Segment'',
   ''Relational Party Segments'',
   ''party'',
   ''rel_segments'',
   ''segment_id'',
   ''rel_segment'',
   ''f'',
   ''rel_segment'',
   ''rel_segment.name''
   );

  return 0;
end;' language 'plpgsql';

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
                        constraint rel_segments_pk primary key,
        segment_name    varchar(230) not null,
        group_id        integer not null
                        constraint rel_segments_group_id_fk
                        references groups (group_id),
        rel_type        varchar(100) not null
                        constraint rel_segments_rel_type_fk
                        references acs_rel_types (rel_type),
        constraint rel_segments_grp_rel_type_uq unique(group_id, rel_type)
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

-- create or replace package rel_segment
-- is
--  function new (
--   --/** Creates a new relational segment
--   -- 
--   --    @author Oumi Mehrotra (oumi@arsdigita.com)
--   --    @creation-date 12/2000
--   -- 
--   --*/
--   segment_id            in rel_segments.segment_id%TYPE default null,
--   object_type           in acs_objects.object_type%TYPE
--                            default 'rel_segment',
--   creation_date         in acs_objects.creation_date%TYPE
--                            default sysdate,
--   creation_user         in acs_objects.creation_user%TYPE
--                            default null,
--   creation_ip           in acs_objects.creation_ip%TYPE default null,
--   email                 in parties.email%TYPE default null,
--   url                   in parties.url%TYPE default null,
--   segment_name          in rel_segments.segment_name%TYPE,
--   group_id              in rel_segments.group_id%TYPE,
--   rel_type              in rel_segments.rel_type%TYPE,
--   context_id	in acs_objects.context_id%TYPE default null
--  ) return rel_segments.segment_id%TYPE;
-- 
--  procedure delete (
--     --/** Deletes a relational segment
--     -- 
--     --    @author Oumi Mehrotra (oumi@arsdigita.com)
--     --    @creation-date 12/2000
--     -- 
--     --*/
--    segment_id     in rel_segments.segment_id%TYPE
--  );
-- 
--  function name (
--   segment_id      in rel_segments.segment_id%TYPE
--  ) return rel_segments.segment_name%TYPE;
-- 
--  function get (
--     --/** EXPERIMENTAL / UNSTABLE -- use at your own risk
--     --    Get the id of a segment given a group_id and rel_type.
--     --    This depends on the uniqueness of group_id,rel_type.  We
--     --    might remove the unique constraint in the future, in which
--     --    case we would also probably remove this function.
--     --
--     --    @author Oumi Mehrotra (oumi@arsdigita.com)
--     --    @creation-date 12/2000
--     --
--     --*/
-- 
--    group_id       in rel_segments.group_id%TYPE,
--    rel_type       in rel_segments.rel_type%TYPE
--  ) return rel_segments.segment_id%TYPE;
-- 
--  function get_or_new (
--     --/** EXPERIMENTAL / UNSTABLE -- use at your own risk
--     --
--     --    This function simplifies the use of segments a little by letting
--     --    you not have to worry about creating and initializing segments.
--     --    If the segment you're interested in exists, this function
--     --    returns its segment_id.
--     --    If the segment you're interested in doesn't exist, this function
--     --    does a pretty minimal amount of initialization for the segment
--     --    and returns a new segment_id.
--     --
--     --    @author Oumi Mehrotra (oumi@arsdigita.com)
--     --    @creation-date 12/2000
--     --
--     --*/
--    group_id       in rel_segments.group_id%TYPE,
--    rel_type       in rel_segments.rel_type%TYPE,
--    segment_name   in rel_segments.segment_name%TYPE
--                   default null
--  ) return rel_segments.segment_id%TYPE;
-- 
-- end rel_segment;

-- show errors


-----------
-- Views --
-----------

-- create view rel_segment_party_map
-- as select rs.segment_id, gem.element_id as party_id, gem.rel_id, gem.rel_type, 
--           gem.group_id, gem.container_id, gem.ancestor_rel_type
--    from rel_segments rs, 
--         group_element_map gem 
--    where gem.group_id = rs.group_id
--      and rs.rel_type in (select object_type 
--                          from acs_object_types 
--                          start with object_type = gem.rel_type 
--                          connect by prior supertype = object_type);

create view rel_segment_party_map
as select rs.segment_id, gem.element_id as party_id, gem.rel_id, gem.rel_type, 
          gem.group_id, gem.container_id, gem.ancestor_rel_type
   from rel_segments rs, group_element_map gem, acs_object_types o1, acs_object_types o2
   where gem.group_id = rs.group_id
     and o1.object_type = gem.rel_type
     and o2.object_type = rs.rel_type
     and o1.tree_sortkey between o2.tree_sortkey and tree_right(o2.tree_sortkey);

create view rel_segment_distinct_party_map
as select distinct segment_id, party_id, ancestor_rel_type
   from rel_segment_party_map;

create view rel_segment_member_map
as select segment_id, party_id as member_id, rel_id, rel_type, 
          group_id, container_id
   from rel_segment_party_map
   where ancestor_rel_type = 'membership_rel';


-- Need to find out what this optimizer hint does?  DCW, 2001-03-13.
-- create view rel_seg_approved_member_map
-- as select /*+ ordered */ 
--           rs.segment_id, gem.element_id as member_id, gem.rel_id, gem.rel_type, 
--           gem.group_id, gem.container_id
--     from membership_rels mr, group_element_map gem, rel_segments rs
--    where rs.group_id = gem.group_id 
--      and rs.rel_type in (select object_type 
--                          from acs_object_types 
--                          start with object_type = gem.rel_type 
--                          connect by prior supertype = object_type)
--      and mr.rel_id = gem.rel_id and mr.member_state = 'approved';


create view rel_seg_approved_member_map
as select rs.segment_id, gem.element_id as member_id, gem.rel_id, 
          gem.rel_type, gem.group_id, gem.container_id
    from membership_rels mr, group_element_map gem, rel_segments rs,
         acs_object_types o1, acs_object_types o2
   where rs.group_id = gem.group_id 
     and rs.rel_type = o2.object_type
     and o1.object_type = gem.rel_type 
     and o1.tree_sortkey between o2.tree_sortkey and tree_right(o2.tree_sortkey)
     and mr.rel_id = gem.rel_id and mr.member_state = 'approved';

create view rel_seg_distinct_member_map
as select distinct segment_id, member_id
   from rel_seg_approved_member_map;


-- party_member_map can be used to expand any party into its members.  
-- Every party is considered to be a member of itself.

-- By the way, aren't the party_member_map and party_approved_member_map 
-- views equivalent??  (TO DO: RESOLVE THIS QUESTION)

create view party_member_map
as select segment_id as party_id, member_id
   from rel_seg_distinct_member_map
   union
   select group_id as party_id, member_id
   from group_distinct_member_map
   union
   select party_id, party_id as member_id
   from parties;

create view party_approved_member_map
as select distinct segment_id as party_id, member_id
   from rel_seg_approved_member_map
   union
   select distinct group_id as party_id, member_id
   from group_approved_member_map
   union
   select party_id, party_id as member_id
   from parties;

-- party_element_map tells us all the parties that "belong to" a party,
-- whether through somet type of membership, composition, or identity.

create view party_element_map
as select distinct group_id as party_id, element_id
   from group_element_map
   union
   select distinct segment_id as party_id, party_id as element_id
   from rel_segment_party_map
   union
   select party_id, party_id as element_id
   from parties;


-- View: rel_segment_group_rel_type_map
--
-- Result Set: the set of triples (:segment_id, :group_id, :rel_type) such that
--
--             IF a party were to be in :group_id 
--                through a relation of type :rel_type,
--             THEN the party would necessarily be in segment :segemnt_id.    
--
--
-- create view rel_segment_group_rel_type_map as
-- select s.segment_id, 
--        gcm.component_id as group_id, 
--        acs_rel_types.rel_type as rel_type
-- from rel_segments s,
--      (select group_id, component_id
--       from group_component_map
--       UNION ALL
--       select group_id, group_id as component_id
--       from groups) gcm,
--      acs_rel_types
-- where s.group_id = gcm.group_id
--   and s.rel_type in (select object_type from acs_object_types
--                      start with object_type = acs_rel_types.rel_type
--                      connect by prior supertype = object_type);
 
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
     acs_object_types o1, acs_object_types o2
where s.group_id = gcm.group_id
  and s.rel_type = o2.object_type
  and o1.object_type = acs_rel_types.rel_type
  and o1.tree_sortkey between o2.tree_sortkey and tree_right(o2.tree_sortkey);
 
