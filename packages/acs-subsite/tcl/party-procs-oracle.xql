<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<partialquery name="party::types_valid_for_rel_type_multirow.start_with_clause_party">
      <querytext>
        (object_type = 'group' or object_type = 'person')
      </querytext>
</partialquery>	      

<partialquery name="party::types_valid_for_rel_type_multirow.start_with_clause">
      <querytext>
        object_type = :start_with
      </querytext>
</partialquery>	      

<fullquery name="party::types_valid_for_rel_type_multirow.select_sub_rel_types">      
      <querytext>
      
	select 
	    types.pretty_name, 
	    types.object_type, 
	    types.tree_level, 
	    types.indent,
	    case when valid_types.object_type = null then 0 else 1 end as valid_p
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
