


select count(*)
where exists (select 1 
               from acs_object_types t 
              where t.object_type = 'user'
         connect by prior t.object_type = t.supertype
         start with t.supertype = 'party');


select count(*)
where exists (select 1 
               from acs_object_types t 
              where t.object_type = 'user'
                and sortkey like (select sortkey || '%' 
                                    from acs_object_types 
                                   where object_type = 'party'));


select object_type
  from acs_object_types o1,  acs_object_types o2
 where o1.object_type = (select object_type
                           from acs_objects o
                          where o.object_id = object_id_in)
   and o2.tree_sortkey <= o1.tree_sortkey
   and o1.tree_sortkey like (o2.tree_sortkey || '%') 
 order by tree_sortkey desc

;
    select 1 into dummy
    from acs_rel_types rt,
         acs_objects o1, 
         acs_objects o2
    where exists (select 1 
                   from acs_object_types t
                  where t.object_type = o1.object_type
                    and t.tree_sortkey 
                        like (select o.tree_sortkey || '%' 
                                from acs_object_types o
                               where o.object_type = rt.object_type_one))
      and exists (select 1 
                   from acs_object_types t
                  where t.object_type = o2.object_type
                    and t.tree_sortkey 
                        like (select o.tree_sortkey || '%' 
                                from acs_object_types o
                               where o.object_type = rt.object_type_two))
      and rt.rel_type = new.rel_type
      and o1.object_id = new.object_id_one
      and o2.object_id = new.object_id_two;

select object_type
  from acs_object_types o1, acs_object_types o2
 where o1.object_type = acs_rel_types.rel_type
   and o2.tree_sortkey <= o1.tree_sortkey
   and o1.tree_sortkey like (o2.tree_sortkey || '%') 
 order by tree_sortkey desc


select object_type as rel_type 
  from acs_object_types
start with object_type = 'membership_rel'
        or object_type = 'composition_rel'
   connect by supertype = prior object_type

select object_type as rel_type 
  from acs_object_types
 where tree_sortkey like (select o.tree_sortkey || '%' 
                            from acs_object_types o
                           where o.object_type = 'composition_rel')
    or tree_sortkey like (select o.tree_sortkey || '%' 
                            from acs_object_types o
                           where o.object_type = 'membership_rel');

start with object_type = 'membership_rel'
        or object_type = 'composition_rel'
   connect by supertype = prior object_type


create view rc_segment_required_seg_map as
select rc.rel_segment, rc.rel_side, rc_required.required_rel_segment
from rel_constraints rc, rel_constraints rc_required 
where rc.rel_segment in (
          select rel_segment
            from rel_constraints
           where tree_sortkey 
                 like 
                 (select tree_sortkey || '%'
                    from rel_constraints
                   where rel_segment = rc_required.rel_segment 
                     and rel_side = 'two'));


create view rc_segment_dependency_levels as
      select rel_segment as segment_id,
             max(tree_level) as dependency_level
       from (select rel_segment, tree_level(tree_sortkey) as tree_level
               from rel_constraints rc1, rel_constraints rc2
              where rc1.tree_sortkey like rc2.tree_sortkey || '%'
                and rc1.rel_side = 'two')
   group by segment_id;




select ot1.object_type, ot1.supertype 
from acs_object_types ot1, acs_object_types ot2
where ot1.sortkey like ot2.sortkey || '%';
