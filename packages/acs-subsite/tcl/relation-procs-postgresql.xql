<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="relation_add.select_rel_violation">      
      <querytext>
      
	    select rel_constraint__violation(:rel_id) 
	
      </querytext>
</fullquery>

 
<fullquery name="relation_remove.relation_delete">      
      <querytext>
      begin ${package_name}.delete(:rel_id); end;
      </querytext>
</fullquery>

 
<fullquery name="relation_segment_has_dependant.others_depend_p">      
      <querytext>
      
	    select case when exists
	             (select 1 from rc_violations_by_removing_rel r where r.rel_id = :rel_id)
	           then 1 else 0 end
	      
    
      </querytext>
</fullquery>

 
<fullquery name="relation_type_is_valid_to_group_p.rel_type_valid_p">      
      <querytext>
      
	    select case when exists
	             (select 1 from rc_valid_rel_types r 
                      where r.group_id = :group_id 
                        and r.rel_type = :rel_type)
	           then 1 else 0 end
	      
    
      </querytext>
</fullquery>

 
<fullquery name="relation_types_valid_to_group_multirow.select_sub_rel_types">      
      <querytext>
      FIX ME OUTER JOIN
FIX ME CONNECT BY
FIX ME ROWNUM

	select 
	    pretty_name, object_type, level, indent,
	    case when valid_types.rel_type = null then 0 else 1 end as valid_p
	from 
	    (select
	        t.pretty_name, t.object_type, level,
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
