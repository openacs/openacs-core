<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_primary_relations">      
      <querytext>

    select repeat('&nbsp;', (t.type_level - 1) * 4) as indent,
           t.pretty_name, t.rel_type
      from (select t2.pretty_name, t2.object_type as rel_type, tree_level(t2.tree_sortkey) - tree_level(t1.tree_sortkey) + 1  as type_level
              from acs_object_types t1,
		   acs_object_types t2
             where t2.tree_sortkey between t1.tree_sortkey and tree_right(t1.tree_sortkey)
	       and t2.object_type not in (select g.rel_type 
                                            from group_type_rels g 
                                           where g.group_type = :group_type)
	       and t1.object_type in ('membership_rel', 'composition_rel')) t,
	    acs_rel_types rel_type
       where t.rel_type = rel_type.rel_type
       and (rel_type.object_type_one = :group_type 
            or acs_object_type__is_subtype_p(rel_type.object_type_one, :group_type) = 't')

      </querytext>
</fullquery>

 
</queryset>
