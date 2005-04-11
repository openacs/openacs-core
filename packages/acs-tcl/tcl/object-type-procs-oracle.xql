<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>                                                                             
<partialquery name="acs_object_type_hierarchy.object_type_not_null">      
      <querytext>

	select object_type,
	       pretty_name,
               '' as indent
	  from acs_object_types
	 start with object_type = :object_type
       connect by prior supertype = object_type
         order by level desc

      </querytext>
</partialquery>
 
<partialquery name="acs_object_type_hierarchy.object_type_is_null">      
      <querytext>

	select object_type,
	       pretty_name,
	       replace(lpad(' ', (level - 1) * $indent_width), ' ', '$indent_string') as indent
	  from acs_object_types
         start with supertype is null
       connect by supertype = prior object_type

      </querytext>
</partialquery>

<fullquery name="acs_object_type::supertype.supertypes">      
      <querytext>
          select object_type
            from acs_object_types
           start with object_type = :subtype
      connect by prior supertype = object_type
           where object_type != :substype
        order by level desc
      </querytext>
</fullquery>

</queryset>
