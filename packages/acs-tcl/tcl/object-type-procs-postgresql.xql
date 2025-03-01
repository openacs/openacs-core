<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>
<partialquery name="acs_object_type_hierarchy.object_type_not_null">
      <querytext>

	select o2.object_type,
	       o2.pretty_name,
               '' as indent,
               tree_level(o2.tree_sortkey) as level
	  from (select *
                  from acs_object_types
                 where object_type = :object_type) o1,
               acs_object_types o2
         where o2.tree_sortkey <= o1.tree_sortkey
           and o1.tree_sortkey between o2.tree_sortkey and tree_right(o2.tree_sortkey)
         order by level desc

      </querytext>
</partialquery>

<partialquery name="acs_object_type_hierarchy.object_type_is_null">
      <querytext>

	select object_type,
	       pretty_name,
               repeat('$indent_string',(tree_level(tree_sortkey) - 1) * $indent_width) as indent
	  from acs_object_types
	 order by tree_sortkey

      </querytext>
</partialquery>

<fullquery name="acs_object_type::supertypes.supertypes">
      <querytext>
      WITH RECURSIVE supertypes AS (
          select supertype as object_type from acs_object_types
          where object_type = :subtype
      UNION
          select ot.supertype as object_type
          from supertypes s, acs_object_types ot
          where ot.object_type = s.object_type and ot.supertype is not NULL
      ) SELECT object_type from supertypes;
      </querytext>
</fullquery>

</queryset>
