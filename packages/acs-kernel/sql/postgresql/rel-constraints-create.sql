--
-- /packages/acs-kernel/sql/rel-constraints-create.sql
-- 
-- Add support for relational constraints based on relational segmentation.
--
-- @author Oumi Mehrotra (oumi@arsdigita.com)
-- @creation-date 2000-11-22
-- @cvs-id rel-constraints-create.sql,v 1.1.4.8 2001/01/23 17:03:58 oumi Exp

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

-- WARNING!
-- Relational constraints is a new and experimental concept.  The API may
-- change in the future, particularly the functions marked "EXPERIMENTAL".
--

create function inline_0 ()
returns integer as '
begin
    PERFORM acs_object_type__create_type (
      ''rel_constraint'',
      ''Relational Constraint'',
      ''Relational Constraints'',
      ''acs_object'',
      ''rel_constraints'',
      ''constraint_id'',
      ''rel_constraint'',
      ''f'',
      null,
      null
      );

      return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();


-- show errors


create table rel_constraints (
    constraint_id		integer
				constraint rel_constraints_pk
					primary key
				constraint rc_constraint_id_fk
					references acs_objects(object_id),
    constraint_name		varchar(100) not null,
    rel_segment 		integer not null
				constraint rc_rel_segment_fk
					references rel_segments (segment_id),
    rel_side                    char(3) default 'two' not null
				constraint rc_rel_side_ck
					check (rel_side in
					('one', 'two')),
    required_rel_segment	integer not null
				constraint rc_required_rel_segment
					references rel_segments (segment_id),
    constraint rel_constraints_uq
	unique (rel_segment, rel_side, required_rel_segment)
);

-- required_rel_segment has a foreign key reference - create an index
create index rel_constraint_req_rel_seg_idx on rel_constraints(required_rel_segment);

comment on table rel_constraints is '
  Defines relational constraints. The relational constraints system is
  intended to support applications in modelling and applying
  constraint rules on inter-party relatinships based on relational
  party segmentation.
';


comment on column rel_constraints.constraint_name is '
  The user-defined name of this constraint.
';

comment on column rel_constraints.rel_segment is '
  The segment for which the constraint is defined.
';

comment on column rel_constraints.rel_side is '
  The side of the relation the constraint applies to.
';

comment on column rel_constraints.required_rel_segment is '
  The segment in which elements must be in to satisfy the constraint.
';



-----------
-- VIEWS --
-----------

-- View rel_constraints_violated_one
--
-- pseudo sql:
--
-- select all the side 'one' constraints
-- from the constraints and the associated relations of rel_segment
-- where the relation's container_id (i.e., object_id_one) is not in the 
-- relational segment required_rel_segment.

-- create view rel_constraints_violated_one as
-- select constrained_rels.*
-- from (select rel_constraints.constraint_id, rel_constraints.constraint_name, 
--              r.rel_id, r.container_id, r.party_id, r.rel_type, 
--              rel_constraints.rel_segment,
--              rel_constraints.rel_side, 
--              rel_constraints.required_rel_segment
--       from rel_constraints, rel_segment_party_map r
--       where rel_constraints.rel_side = 'one'
--         and rel_constraints.rel_segment = r.segment_id
--      ) constrained_rels,
--      rel_segment_party_map rspm
-- where rspm.segment_id(+) = constrained_rels.required_rel_segment
--   and rspm.party_id(+) = constrained_rels.container_id
--   and rspm.party_id is null;

create view constrained_rels1 as 
select rel.constraint_id, rel.constraint_name, 
       r.rel_id, r.container_id, r.party_id, r.rel_type, 
       rel.rel_segment,
       rel.rel_side, 
       rel.required_rel_segment
  from rel_constraints rel, rel_segment_party_map r
 where rel.rel_side = 'one'
   and rel.rel_segment = r.segment_id;
     
create view rel_constraints_violated_one as
select c.*
from   constrained_rels1 c left outer join rel_segment_party_map rspm 
       on (rspm.segment_id = c.required_rel_segment and 
           rspm.party_id = c.container_id)
where rspm.party_id is null;

-- View rel_constraints_violated_two
--
-- pseudo sql:
--
-- select all the side 'two' constraints
-- from the constraints and the associated relations of rel_segment
-- where the relation's party_id (i.e., object_id_two) is not in the 
-- relational segment required_rel_segment.

-- create view rel_constraints_violated_two as
-- select constrained_rels.*
-- from (select rel_constraints.constraint_id, rel_constraints.constraint_name, 
--              r.rel_id, r.container_id, r.party_id, r.rel_type, 
--              rel_constraints.rel_segment,
--              rel_constraints.rel_side, 
--              rel_constraints.required_rel_segment
--       from rel_constraints, rel_segment_party_map r
--       where rel_constraints.rel_side = 'two'
--         and rel_constraints.rel_segment = r.segment_id
--      ) constrained_rels,
--      rel_segment_party_map rspm
-- where rspm.segment_id(+) = constrained_rels.required_rel_segment
--   and rspm.party_id(+) = constrained_rels.party_id
--   and rspm.party_id is null;

create view constrained_rels2 as 
select rel.constraint_id, rel.constraint_name, 
       r.rel_id, r.container_id, r.party_id, r.rel_type, 
       rel.rel_segment,
       rel.rel_side, 
       rel.required_rel_segment
  from rel_constraints rel, rel_segment_party_map r
 where rel.rel_side = 'two'
   and rel.rel_segment = r.segment_id;
     

create view rel_constraints_violated_two as
select c.*
from  constrained_rels2 c left outer join rel_segment_party_map rspm 
       on (rspm.segment_id = c.required_rel_segment and
           rspm.party_id = c.party_id)
where rspm.party_id is null;


-- View: rc_all_constraints
--
-- Question: Given group :group_id and rel_type :rel_type . . .
--
--           What segments must a party be in 
--           if the party were to be on side :rel_side of a relation of 
--           type :rel_type to group :group_id ?
--
-- Answer:   select required_rel_segment
--           from rc_all_constraints
--           where group_id = :group_id
--             and rel_type = :rel_type
--             and rel_side = :rel_side
--
-- Notes: we take special care not to get identity rows, where group_id and 
-- rel_type are equivalent to segment_id.  This can happen if there are some 
-- funky constraints in the system, such as membership to Arsdigita requires 
-- user_profile to Arsdigita. Then you could get rows from the 
-- rc_all_constraints view saying that:
--     user_profile to Arsdigita 
--     requires being in the segment of Arsdigita Users.
--
-- This happens because user_profile is a type of memebrship, and there's a 
-- constraint saying that membership to Arsdigita requires being in the
-- Arsdigita Users segment.  We eliminate such rows from the rc_all_constraints
-- view with the "not (...)" clause below.
--
create view rc_all_constraints as
select group_rel_types.group_id, 
       group_rel_types.rel_type,
       rel_constraints.rel_segment,
       rel_constraints.rel_side,
       required_rel_segment
  from rel_constraints,
       rel_segment_group_rel_type_map group_rel_types,
       rel_segments req_seg
 where rel_constraints.rel_segment = group_rel_types.segment_id
   and rel_constraints.required_rel_segment = req_seg.segment_id
   and not (req_seg.group_id = group_rel_types.group_id and
            req_seg.rel_type = group_rel_types.rel_type);
 

create view rc_all_distinct_constraints as
select distinct 
       group_id, rel_type, rel_segment, rel_side, required_rel_segment
from rc_all_constraints;


-- THIS VIEW IS FOR COMPATIBILITY WITH EXISTING CODE
-- New code should use rc_all_constraints instead!
--
-- View: rc_required_rel_segments
--
-- Question: Given group :group_id and rel_type :rel_type . . .
--
--           What segments must a party be in 
--           if the party were to be belong to group :group_id 
--           through a relation of type :rel_type ?
--
-- Answer:   select required_rel_segment
--           from rc_required_rel_segments
--           where group_id = :group_id
--             and rel_type = :rel_type
--

create view rc_required_rel_segments as
select distinct group_id, rel_type, required_rel_segment
from rc_all_constraints
where rel_side = 'two';

                    
-- View: rc_parties_in_required_segs
--
-- Question: Given group :group_id and rel_type :rel_type . . .
--
--           What parties are "allowed" to be in group :group_id
--           through a relation of type :rel_type ?  By "allowed",
--           we mean that no relational constraints would be violated.
--
-- Answer:   select party_id, acs_object.name(party_id)
--           from parties_in_rc_required_rel_segments
--           where group_id = :group_id
--             and rel_type = :rel_type
--


create view comp_or_member_rel_types as 
select o.object_type as rel_type 
  from acs_object_types o, acs_object_types o1
  where o1.object_type in ('composition_rel', 'membership_rel')
    and o.tree_sortkey between o1.tree_sortkey and tree_right(o1.tree_sortkey);

create view group_rel_type_combos as 
select groups.group_id, comp_or_member_rel_types.rel_type
       from groups, comp_or_member_rel_types;

create view parties_in_required_segs as
select required_segs.group_id,
           required_segs.rel_type,
           seg_parties.party_id,
           seg_parties.segment_id,
           count(*) as num_matching_segs
    from rc_required_rel_segments required_segs,
         rel_segment_party_map seg_parties
    where required_segs.required_rel_segment = seg_parties.segment_id
    group by required_segs.group_id,
             required_segs.rel_type,
             seg_parties.party_id,
             seg_parties.segment_id;

create view total_num_required_segs as 
select group_id, rel_type, count(*) as total
  from rc_required_rel_segments
 group by group_id, rel_type;

create view rc_parties_in_required_segs as
select parties_in_required_segs.group_id,
       parties_in_required_segs.rel_type,
       parties_in_required_segs.party_id
from
    parties_in_required_segs,
    total_num_required_segs
where
      parties_in_required_segs.group_id = total_num_required_segs.group_id
  and parties_in_required_segs.rel_type = total_num_required_segs.rel_type
  and parties_in_required_segs.num_matching_segs = total_num_required_segs.total
UNION ALL
select group_rel_type_combos.group_id,
       group_rel_type_combos.rel_type,
       parties.party_id
from (rc_required_rel_segments right outer join group_rel_type_combos 
      on 
        (rc_required_rel_segments.group_id = group_rel_type_combos.group_id 
         and 
         rc_required_rel_segments.rel_type = group_rel_type_combos.rel_type)),
         parties
where rc_required_rel_segments.group_id is null;


-- View: rc_valid_rel_types
--
-- Question: What types of membership or composition are "valid"
--           for group :group_id ?   A membership or composition 
--           type R is "valid" when no relational constraints would 
--           be violated if a party were to belong to group :group_id 
--           through a rel of type R.
--
-- Answer:   select rel_type
--           from rc_valid_rel_types
--           where group_id = :group_id
--
--
 
-- create view rc_valid_rel_types as
-- select side_one_constraints.group_id, 
--        side_one_constraints.rel_type
--   from (select required_segs.group_id, 
--                required_segs.rel_type, 
--                count(*) as num_satisfied
--           from rc_all_constraints required_segs,
--                rel_segment_party_map map
--          where required_segs.rel_side = 'one'
--            and required_segs.required_rel_segment = map.segment_id
--            and required_segs.group_id = map.party_id
--         group by required_segs.group_id, 
--                  required_segs.rel_type) side_one_constraints,
--        (select group_id, rel_type, count(*) as total
--           from rc_all_constraints
--          where rel_side = 'one'
--         group by group_id, rel_type) total_side_one_constraints
--  where side_one_constraints.group_id = total_side_one_constraints.group_id
--    and side_one_constraints.rel_type = total_side_one_constraints.rel_type
--    and side_one_constraints.num_satisfied = total_side_one_constraints.total
-- UNION ALL
-- select group_rel_type_combos.group_id,
--        group_rel_type_combos.rel_type
-- from (select * from rc_all_constraints where rel_side='one') rc_all_constraints, 
--      (select groups.group_id, comp_or_member_rel_types.rel_type
--       from groups, 
--            (select object_type as rel_type from acs_object_types
--             start with object_type = 'membership_rel'
--                     or object_type = 'composition_rel'
--             connect by supertype = prior object_type) comp_or_member_rel_types
--      ) group_rel_type_combos
-- where rc_all_constraints.group_id(+) = group_rel_type_combos.group_id
--   and rc_all_constraints.rel_type(+) = group_rel_type_combos.rel_type
--   and rc_all_constraints.group_id is null;

create view side_one_constraints as 
select required_segs.group_id, 
               required_segs.rel_type, 
               count(*) as num_satisfied
          from rc_all_constraints required_segs,
               rel_segment_party_map map
         where required_segs.rel_side = 'one'
           and required_segs.required_rel_segment = map.segment_id
           and required_segs.group_id = map.party_id
        group by required_segs.group_id, 
                 required_segs.rel_type;

create view total_side_one_constraints as 
select group_id, rel_type, count(*) as total
  from rc_all_constraints
 where rel_side = 'one'
 group by group_id, rel_type;

create view rc_all_constraints_view as 
select * from rc_all_constraints where rel_side='one';

create view rc_valid_rel_types as
select side_one_constraints.group_id, 
       side_one_constraints.rel_type
  from side_one_constraints,
       total_side_one_constraints
 where side_one_constraints.group_id = total_side_one_constraints.group_id
   and side_one_constraints.rel_type = total_side_one_constraints.rel_type
   and side_one_constraints.num_satisfied = total_side_one_constraints.total
UNION ALL
select group_rel_type_combos.group_id,
       group_rel_type_combos.rel_type
from rc_all_constraints_view right outer join group_rel_type_combos
      on 
     (rc_all_constraints_view.group_id = group_rel_type_combos.group_id and 
      rc_all_constraints_view.rel_type = group_rel_type_combos.rel_type)
where rc_all_constraints_view.group_id is null;


-- View: rc_violations_by_removing_rel
--
-- Question: Given relation :rel_id
--
--           If we were to remove the relation specified by rel_id, 
--           what constraints would be violated and by what parties?
--
-- Answer:   select r.rel_id, r.constraint_id, r.constraint_name
--	            acs_object_type.pretty_name(r.rel_type) as rel_type_pretty_name,
--	            acs_object.name(r.object_id_one) as object_id_one_name, 
--	            acs_object.name(r.object_id_two) as object_id_two_name
--	       from rc_violations_by_removing_rel r
--	      where r.rel_id = :rel_id
--        

create view rc_violations_by_removing_rel as
select r.rel_type as viol_rel_type, r.rel_id as viol_rel_id, 
       r.object_id_one as viol_object_id_one, r.object_id_two as viol_object_id_two,
       s.rel_id,
       cons.constraint_id, cons.constraint_name,
       map.segment_id, map.party_id, map.group_id, map.container_id, map.ancestor_rel_type
  from acs_rels r, rel_segment_party_map map, rel_constraints cons,
               (select s.segment_id, r.rel_id, r.object_id_two
                  from rel_segments s, acs_rels r
                 where r.object_id_one = s.group_id
                   and r.rel_type = s.rel_type) s
 where map.party_id = r.object_id_two
   and map.rel_id = r.rel_id
   and r.object_id_two = s.object_id_two
   and cons.rel_segment = map.segment_id
   and cons.required_rel_segment = s.segment_id;

 
-- View: rc_segment_required_seg_map
--
-- Question: Given a relational segment :rel_segment . . .
--
--           What are all the segments in the system that a party has to 
--           be in if the party were to be on side :rel_side of a relation
--           in segement :rel_segment?  
--
--           We want not only the direct required_segments (which we could
--           get from the rel_constraints table directly), but also the 
--           indirect ones (i.e., the segments that are required by the 
--           required segments, and so on).
--
-- Answer:   select required_rel_segment
--           from rc_segment_required_seg_map
--           where rel_segment = :rel_segment
--             and rel_side = :rel_side
--
--
-- create view rc_segment_required_seg_map as
-- select rc.rel_segment, rc.rel_side, rc_required.required_rel_segment
-- from rel_constraints rc, rel_constraints rc_required 
-- where rc.rel_segment in (
--           select rel_segment
--           from rel_constraints
--           start with rel_segment = rc_required.rel_segment
--           connect by required_rel_segment = prior rel_segment
--                  and prior rel_side = 'two'
--       );

-- DCW 2001-04-19, replaced view with a table and a trigger since a tree query
-- won't work on the rel_constraints table, because instead of a tree, we have 
-- a directed graph structure.

create table rc_segment_required_seg_map (
    rel_segment 		integer not null
				constraint rc_rel_segment_fk
					references rel_segments (segment_id),
    rel_side                    char(3) not null
				constraint rc_rel_side_ck
					check (rel_side in
					('one', 'two')),
    required_rel_segment	integer not null
				constraint rc_required_rel_segment
					references rel_segments (segment_id),
    constraint rc_segment_required_seg_map_uq
	unique (rel_segment, rel_side, required_rel_segment)
);

create index rc_segment_required_seg_idx on 
rc_segment_required_seg_map(required_rel_segment);

create function rel_constraints_ins_tr () returns opaque as '
declare
        v_rec   record;
begin
        -- insert the constraint

        insert into rc_segment_required_seg_map
               (rel_segment, rel_side, required_rel_segment)
               values
               (new.rel_segment, new.rel_side, new.required_rel_segment);

        -- add dependencies

        insert into rc_segment_required_seg_map
             select new.rel_segment, new.rel_side, required_rel_segment
               from rc_segment_required_seg_map
              where rel_segment = new.required_rel_segment
                and rel_side = new.rel_side;

        -- now update the rel_segments that depend on this segment
        
        for v_rec in select rel_segment 
                       from rc_segment_required_seg_map
                      where required_rel_segment = new.rel_segment 
                        and rel_side = new.rel_side
        LOOP
                insert into rc_segment_required_seg_map
                     select v_rec.rel_segment, new.rel_side, 
                            required_rel_segment
                       from rc_segment_required_seg_map
                      where rel_segment = new.rel_segment
                        and rel_side = new.rel_side;
                
        end LOOP;

        return new;

end;' language 'plpgsql';

create trigger rel_constraints_ins_tr after insert 
on rel_constraints for each row 
execute procedure rel_constraints_ins_tr ();

create function rel_constraints_del_tr () returns opaque as '
declare
        v_rec   record;
begin

        -- now update the rel_segments that depend on this segment
        
        for v_rec in select rel_segment 
                       from rc_segment_required_seg_map
                      where required_rel_segment = old.rel_segment 
                        and rel_side = old.rel_side
        LOOP

                delete from rc_segment_required_seg_map
                      where rel_segment = v_rec.rel_segment
                        and rel_side = old.rel_side
                        and required_rel_segment 
                            in (select required_rel_segment
                                  from rc_segment_required_seg_map
                                 where rel_segment = old.rel_segment
                                   and rel_side = old.rel_side);
                
        end LOOP;

        -- delete dependencies

        delete from rc_segment_required_seg_map
              where rel_segment = old.rel_segment
                and rel_side = old.rel_side
                and required_rel_segment 
                    in (select required_rel_segment
                          from rc_segment_required_seg_map
                         where rel_segment = old.required_rel_segment
                           and rel_side = old.rel_side);

        -- delete the constraint

        delete from rc_segment_required_seg_map
              where rel_segment = old.rel_segment
                and rel_side = old.rel_side 
                and required_rel_segment = old.required_rel_segment;

        return old;

end;' language 'plpgsql';

create trigger rel_constraints_del_tr after delete
on rel_constraints for each row 
execute procedure rel_constraints_del_tr ();



-- View: rc_segment_dependency_levels
--
-- This view is designed to determine what order of segments is safe
-- to use when adding a party to multiple segments.
--
-- Question: Given a table or view called segments_I_want_to_be_in,
--           which segments can I add a party to first, without violating
--           any relational constraints?
--
-- Answer:   select segment_id
--           from segments_I_want_to_be_in s,
--                rc_segment_dependency_levels dl
--           where s.segment_id = dl.segment_id(+)
--           order by nvl(dl.dependency_level, 0)
--
-- Note: dependency_level = 1 is the minimum dependency level.
--       dependency_level = N means that you cannot add a party to the
--                          segment until you first add the party to some
--                          segment of dependency_level N-1 (this view doesn't
--                          tell you which segment -- you can get that info
--                          from rel_constraints table or other views.
--
-- Another Note: not all segemnts in rel_segemnts are returned by this view.
-- This view only returns segments S that have at least one rel_constraints row
-- where rel_segment = S.  Segments that have no constraints defined on them
-- can be said to have dependency_level=0, hence the outer join and nvl in the
-- example query above (see "Answer:").  I could have embeded that logic into
-- this view, but that would unnecessarily degrade performance.
--
-- create view rc_segment_dependency_levels as
--       select rel_segment as segment_id,
--              max(tree_level) as dependency_level
--       from (select rel_segment, level as tree_level
--             from rel_constraints
--             connect by required_rel_segment = prior rel_segment
--                 and prior rel_side = 'two')
--       group by rel_segment;

-- DCW 2001-04-19, this view is not a direct port rather it gives equivalent
-- information without the use of a tree query, which in this case would be
-- problematic, since we are actually dealing with a directed graph instead 
-- of a tree structure.  This view would also work for oracle.


create view rc_segment_dependency_levels as 
  select rel_segment as segment_id, count(*) as dependency_level
    from rc_segment_required_seg_map
   where rel_side = 'two'
group by segment_id;

--------------
-- PACKAGES --
--------------


-- create or replace package rel_constraint
-- as
-- 
--   function new (
--     --/** Creates a new relational constraint
--     -- 
--     --    @author Oumi Mehrotra (oumi@arsdigita.com)
--     --    @creation-date 12/2000
--     -- 
--     --*/
--     constraint_id	in rel_constraints.constraint_id%TYPE default null,
--     constraint_type     in acs_objects.object_type%TYPE default 'rel_constraint',
--     constraint_name	in rel_constraints.constraint_name%TYPE,
--     rel_segment		in rel_constraints.rel_segment%TYPE,
--     rel_side	        in rel_constraints.rel_side%TYPE default 'two',
--     required_rel_segment in rel_constraints.required_rel_segment%TYPE,
--     context_id		in acs_objects.context_id%TYPE default null,
--     creation_user	in acs_objects.creation_user%TYPE default null,
--     creation_ip		in acs_objects.creation_ip%TYPE default null
--   ) return rel_constraints.constraint_id%TYPE;
-- 
--   procedure delete (
--     constraint_id	in rel_constraints.constraint_id%TYPE
--   );
-- 
--   function get_constraint_id (
--     --/** Returns the constraint_id associated with the specified
--     --    rel_segment and required_rel_segment for the specified site.
--     -- 
--     --    @author Oumi Mehrotra (oumi@arsdigita.com)
--     --    @creation-date 12/2000
--     -- 
--     --*/
--     rel_segment		in rel_constraints.rel_segment%TYPE,
--     rel_side	        in rel_constraints.rel_side%TYPE default 'two',
--     required_rel_segment in rel_constraints.required_rel_segment%TYPE
--   ) return rel_constraints.constraint_id%TYPE;
-- 
--   function violation (
--     --/** Checks to see if there a relational constraint is violated
--     --    by the precense of the specified relation. If not, returns 
--     --    null. If so, returns an appropriate error string.
--     -- 
--     --    @author Oumi Mehrotra (oumi@arsdigita.com)
--     --    @creation-date 12/2000
--     -- 
--     --    @param rel_id  The relation for which we want to find 
--     --                   any violations
--     --*/
--     rel_id	in acs_rels.rel_id%TYPE
--   ) return varchar;
-- 
-- 
--   function violation_if_removed (
--     --/** Checks to see if removing the specified relation would violate
--     --    a relational constraint. If not, returns null. If so, returns
--     --    an appropriate error string.
--     -- 
--     --    @author Michael Bryzek (mbryzek@arsdigita.com)
--     --    @creation-date 1/2001
--     -- 
--     --    @param rel_id  The relation that we are planning to remove
--     --*/
--     rel_id	in acs_rels.rel_id%TYPE
--   ) return varchar;
-- 
-- end;

-- show errors
