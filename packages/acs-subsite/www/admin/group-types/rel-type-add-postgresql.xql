<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_primary_relations">      
      <querytext>
    select lpad('&nbsp;', (t.type_level - 1) * 4) as indent,
           t.pretty_name, t.rel_type
      from (select t.pretty_name, t.object_type as rel_type, tree_level(tree_sortkey) as type_level
              from acs_object_types t
             where t.object_type not in (select g.rel_type 
                                           from group_type_rels g 
                                          where g.group_type = :group_type)
	 and (t.tree_sortkey like (select tree_sortkey || '%' from acs_object_types where object_type = 'membership_rel')
		or t.tree_sortkey like (select tree_sortkey || '%' from acs_object_types where object_type = 'composition_rel'))) t, acs_rel_types rel_type

       where t.rel_type = rel_type.rel_type
       and (rel_type.object_type_one = :group_type 
            or acs_object_type__is_subtype_p(rel_type.object_type_one, :group_type) = 't')

      </querytext>
</fullquery>

 
</queryset>
