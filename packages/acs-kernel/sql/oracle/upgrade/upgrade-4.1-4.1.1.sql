--
-- /packages/acs-kernel/sql/upgrade/upgrade-4.1-4.1.1.sql
-- 
-- Upgrades ACS Kernel 4.1 to ACS Kernel 4.1.1
--
-- @author Multiple
-- @creation-date 2001-01-23
-- @cvs-id $Id$


--------------------------------------------------------------
-- Relational Constraints Views
-- oumi@arsdigita.com
-- 1/23/2001
--
-- CHANGES
-- Added some views and modified one view to fix minor bugs
-- and make it possible to fix some UI issues in ACS Subsites
--------------------------------------------------------------

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
create or replace view rc_all_constraints as
select group_ancestor_map.group_id, 
       type_map.object_type as rel_type,
       rel_constraints.rel_segment,
       rel_constraints.rel_side,
       required_rel_segment
  from rel_constraints,
       rel_segments,
       (select object_type, ancestor_type
        from acs_object_type_supertype_map
        union all
        select object_type, object_type 
        from acs_object_types) type_map,
       (select component_id as group_id,
               group_id as ancestor_group_id
          from group_component_map
        union all
        select group_id as component_group_id,
               group_id as ancestor_group_id
          from groups) group_ancestor_map
 where rel_constraints.rel_segment = rel_segments.segment_id
   and rel_segments.group_id = group_ancestor_map.ancestor_group_id
   and rel_segments.rel_type = type_map.ancestor_type;


create or replace view rc_all_distinct_constraints as
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

create or replace view rc_required_rel_segments as
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
create or replace view rc_parties_in_required_segs as
select parties_in_required_segs.group_id,
       parties_in_required_segs.rel_type,
       parties_in_required_segs.party_id
from
   (select required_segs.group_id, 
           required_segs.rel_type, 
           seg_parties.party_id,
           count(*) as num_matching_segs
    from rc_required_rel_segments required_segs,
         rel_segment_party_map seg_parties
    where required_segs.required_rel_segment = seg_parties.segment_id
    group by required_segs.group_id, 
             required_segs.rel_type, 
             seg_parties.party_id) parties_in_required_segs,
   (select group_id, rel_type, count(*) as total
    from rc_required_rel_segments
    group by group_id, rel_type) total_num_required_segs
where
      parties_in_required_segs.group_id = total_num_required_segs.group_id
  and parties_in_required_segs.rel_type = total_num_required_segs.rel_type
  and parties_in_required_segs.num_matching_segs = total_num_required_segs.total
UNION ALL
select group_rel_type_combos.group_id,
       group_rel_type_combos.rel_type,
       parties.party_id
from rc_required_rel_segments, 
     (select groups.group_id, comp_or_member_rel_types.rel_type
      from groups,
           (select object_type as rel_type from acs_object_types
            start with object_type = 'membership_rel'
                    or object_type = 'composition_rel'
            connect by supertype = prior object_type) comp_or_member_rel_types
     ) group_rel_type_combos,
     parties
where rc_required_rel_segments.group_id(+) = group_rel_type_combos.group_id
  and rc_required_rel_segments.rel_type(+) = group_rel_type_combos.rel_type
  and rc_required_rel_segments.group_id is null;


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
create or replace view rc_valid_rel_types as
select side_one_constraints.group_id, 
       side_one_constraints.rel_type
  from (select required_segs.group_id, 
               required_segs.rel_type, 
               count(*) as num_satisfied
          from rc_all_constraints required_segs,
               rel_segment_party_map map
         where required_segs.rel_side = 'one'
           and required_segs.required_rel_segment = map.segment_id
           and required_segs.group_id = map.party_id
        group by required_segs.group_id, 
                 required_segs.rel_type) side_one_constraints,
       (select group_id, rel_type, count(*) as total
          from rc_all_constraints
         where rel_side = 'one'
        group by group_id, rel_type) total_side_one_constraints
 where side_one_constraints.group_id = total_side_one_constraints.group_id
   and side_one_constraints.rel_type = total_side_one_constraints.rel_type
   and side_one_constraints.num_satisfied = total_side_one_constraints.total
UNION ALL
select group_rel_type_combos.group_id,
       group_rel_type_combos.rel_type
from rc_all_constraints, 
     (select groups.group_id, comp_or_member_rel_types.rel_type
      from groups, 
           (select object_type as rel_type from acs_object_types
            start with object_type = 'membership_rel'
                    or object_type = 'composition_rel'
            connect by supertype = prior object_type) comp_or_member_rel_types
     ) group_rel_type_combos
where rc_all_constraints.group_id(+) = group_rel_type_combos.group_id
  and rc_all_constraints.rel_type(+) = group_rel_type_combos.rel_type
  and rc_all_constraints.group_id is null;

