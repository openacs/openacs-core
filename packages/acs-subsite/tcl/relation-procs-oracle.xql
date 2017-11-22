<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="relation_add.select_rel_violation">      
      <querytext>
      
	    select rel_constraint.violation(:rel_id) from dual
	
      </querytext>
</fullquery>
 
<fullquery name="relation_remove.relation_delete">      
      <querytext>
      begin ${package_name}.del(:rel_id); end;
      </querytext>
</fullquery>
 
<fullquery name="relation_types_valid_to_group_multirow.select_sub_rel_types">      
      <querytext>
      
	select 
	    pretty_name, object_type, indent,
	    case when valid_types.rel_type = null then 0 else 1 end as valid_p
	from 
	    (select
	        t.pretty_name, t.object_type,
	        replace(lpad(' ', (level - 1) * 4), 
	                ' ', '&nbsp;') as indent,
	        rownum as tree_rownum
	     from 
	        acs_object_types t
	     connect by 
	        prior t.object_type = t.supertype
	     start with 
	        t.object_type = :start_with ) types,
	    (select 
	        rel_type 
	     from 
	        rc_valid_rel_types
	     where 
	        group_id = :group_id ) valid_types
	where 
	    types.object_type = valid_types.rel_type(+)
	order by tree_rownum
    
      </querytext>
</fullquery>

</queryset>
