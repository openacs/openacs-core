--- This change addresses the problem mentioned in
---     https://cvs.openacs.org/changelog/OpenACS?cs=oacs-5-10%3Agustafn%3A20220729185340
---     https://github.com/openacs/openacs-core/commit/be44691f06627678122bd913bc3c95c80e93f403
---
--- which happens in some legacy applications (such as
--- e.g. openacs.org) where the data types of the following two
--- attributes are different.
---
---      acs_object_types.object_type
---      acs_objects.object_type
---
--- On new installations (at least concerning the last 10 years) these
--- data types are the same.  So, probably an update script was missing
--- ages ago.
---
--- Since this change affects the basic object structure, MANY views
--- depend on this datatype and have to be dropped and recreate to
--- allow the correction of the datatype.
--- 
--- Therefore, we do not want to run this script on all sites, but
--- only on those where it is necessary.
---

DO $$
  DECLARE v_found boolean;
BEGIN

  -- The following views exists on some (?) legacy installations
  -- (e.g. openacs.org), but are not created/used in recent versions
  -- of OpenACS.

  drop view if exists acs_grantee_party_map; -- legacy view
  drop view if exists party_element_map;     -- legacy view

  SELECT exists(
           SELECT column_name, data_type, character_maximum_length, character_octet_length
           FROM   information_schema.columns
           WHERE table_schema='public' AND table_name = 'acs_object_types'
           AND   column_name='object_type' AND character_maximum_length != 1000
  ) INTO v_found;

  IF v_found THEN
     drop view rel_seg_distinct_member_map;
     drop view rel_seg_approved_member_map;

     drop view rel_types_valid_obj_one_types;
     drop view rel_types_valid_obj_two_types;
     drop view acs_object_type_attributes;
     drop view acs_object_type_supertype_map;

     drop view rc_parties_in_required_segs;
     drop view rc_valid_rel_types;
     drop view group_rel_type_combos;
     drop view comp_or_member_rel_types;

     drop view rel_constraints_violated_one;
     drop view constrained_rels1;
     drop view rel_constraints_violated_two;
     drop view constrained_rels2;

     drop view parties_in_required_segs;
     drop view side_one_constraints;
     drop view rc_violations_by_removing_rel;
     drop view rel_segment_distinct_party_map;
     drop view rel_segment_member_map;
     drop view rel_segment_party_map;

     drop view total_num_required_segs;
     drop view rc_required_rel_segments;
     drop view rc_all_constraints_view;
     drop view rc_all_distinct_constraints;
     drop view total_side_one_constraints;
     drop view rc_all_constraints;
     drop view rel_segment_group_rel_type_map;

     alter table acs_object_types ALTER COLUMN object_type TYPE varchar(1000);

     create view acs_object_type_supertype_map
     as select ot1.object_type, ot2.object_type as ancestor_type
          from acs_object_types ot1,
               acs_object_types ot2
         where ot1.object_type <> ot2.object_type
           and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey);

     create view acs_object_type_attributes as
     select all_types.object_type, all_types.ancestor_type,
            attr.attribute_id, attr.table_name, attr.attribute_name,
            attr.pretty_name, attr.pretty_plural, attr.sort_order,
            attr.datatype, attr.default_value, attr.min_n_values,
            attr.max_n_values, attr.storage, attr.static_p, attr.column_name
     from acs_attributes attr,
          (select map.object_type, map.ancestor_type
           from acs_object_type_supertype_map map, acs_object_types t
           where map.object_type=t.object_type
           UNION ALL
           select t.object_type, t.object_type as ancestor_type
             from acs_object_types t) all_types
     where attr.object_type = all_types.ancestor_type;

     create view rel_types_valid_obj_one_types as
     select rt.rel_type, th.object_type
     from acs_rel_types rt,
          (select object_type, ancestor_type
           from acs_object_type_supertype_map
           UNION ALL
           select object_type, object_type as ancestor_type
           from acs_object_types) th
     where rt.object_type_one = th.ancestor_type;

     create view rel_types_valid_obj_two_types as
     select rt.rel_type, th.object_type
     from acs_rel_types rt,
          (select object_type, ancestor_type
           from acs_object_type_supertype_map
           UNION ALL
           select object_type, object_type as ancestor_type
           from acs_object_types) th
     where rt.object_type_two = th.ancestor_type;

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

     create view comp_or_member_rel_types as
     select o.object_type as rel_type
       from acs_object_types o, acs_object_types o1
       where o1.object_type in ('composition_rel', 'membership_rel')
         and o.tree_sortkey between o1.tree_sortkey and tree_right(o1.tree_sortkey);

     create view group_rel_type_combos as
     select groups.group_id, comp_or_member_rel_types.rel_type
            from groups, comp_or_member_rel_types;

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

     create view rc_required_rel_segments as
     select distinct group_id, rel_type, required_rel_segment
     from rc_all_constraints
     where rel_side = 'two';

     create view rel_segment_party_map
     as select rs.segment_id, gem.element_id as party_id, gem.rel_id, gem.rel_type,
               gem.group_id, gem.container_id, gem.ancestor_rel_type
        from rel_segments rs, group_element_map gem, acs_object_types ot1, acs_object_types ot2
        where gem.group_id = rs.group_id
          and ot1.object_type = gem.rel_type
          and ot2.object_type = rs.rel_type
          and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey);

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

     create view rc_all_constraints_view as
     select * from rc_all_constraints where rel_side='one';

     create view total_side_one_constraints as
     select group_id, rel_type, count(*) as total
       from rc_all_constraints
      where rel_side = 'one'
      group by group_id, rel_type;

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

     create view rel_segment_distinct_party_map
     as select distinct segment_id, party_id, ancestor_rel_type
        from rel_segment_party_map;

     create view rel_segment_member_map
     as select segment_id, party_id as member_id, rel_id, rel_type,
               group_id, container_id
        from rel_segment_party_map
        where ancestor_rel_type = 'membership_rel';

     create view rc_all_distinct_constraints as
     select distinct
            group_id, rel_type, rel_segment, rel_side, required_rel_segment
     from rc_all_constraints;

  END IF;
END $$;
