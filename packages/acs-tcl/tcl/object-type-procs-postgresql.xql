<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>                                                                             
<partialquery name="acs_object_type_hierarchy.object_type_not_null">      
      <querytext>

	select object_type,
	       pretty_name,
               '' as indent,
               tree_level(o2.tree_sortkey) as level
	  from (select * 
                  from acs_object_types 
                 where object_type = :object_type) o1, 
               acs_object_types o2
         where o2.tree_sortkey <= o1.tree_sortkey
           and o1.tree_sortkey like (o2.tree_sortkey || '%')
         order by level desc

      </querytext>
</partialquery>
 
<partialquery name="acs_object_type_hierarchy.object_type_is_null">      
      <querytext>

	select object_type,
	       pretty_name,
               repeat('$indent_string',(tree_level(tree_sortkey) - 1) * $indent_width) as indent
	  from acs_object_types
         where tree_sortkey like (select tree_sortkey || '%'
                                    from acs_object_types
                                   where supertype is null)

      </querytext>
</partialquery>

</queryset>
