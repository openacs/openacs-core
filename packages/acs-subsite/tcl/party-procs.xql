<?xml version="1.0"?>
<queryset>

<fullquery name="new.package_select">      
      <querytext>
      
	    select t.package_name, lower(t.id_column) as id_column
	      from acs_object_types t
	     where t.object_type = :party_type
	
      </querytext>
</fullquery>

 
<fullquery name="types_valid_for_rel_type_multirow.select_sub_rel_types">      
      <querytext>
--      FIX ME DECODE (USE SQL92 CASE) 
	select 
	    types.pretty_name, 
	    types.object_type, 
	    types.tree_level, 
	    types.indent,
	    decode(valid_types.object_type, null, 0, 1) as valid_p
	from 
	    (select
	        t.pretty_name, t.object_type, level as tree_level,
	        replace(lpad(' ', (level - 1) * 4), 
	                ' ', '&nbsp;') as indent,
	        rownum as tree_rownum
	     from 
	        acs_object_types t
	     connect by 
	        prior t.object_type = t.supertype
	     start with 
	        $start_with_clause ) types,
	    (select 
	        object_type 
	     from 
	        rel_types_valid_obj_two_types
	     where 
	        rel_type = :rel_type ) valid_types
	where 
	    types.object_type = valid_types.object_type(+)
	order by tree_rownum
	
      </querytext>
</fullquery>

 
</queryset>
