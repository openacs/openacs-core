<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="attribute_for_dynamic_object_p">      
      <querytext>
      
	select case when exists (select 1 
                                   from acs_attributes a, acs_object_types t
                                  where t.dynamic_p = 't'
                                    and a.object_type = t.object_type
                                    and a.attribute_id = :value)
	            then 1 else 0 end
	  
    
      </querytext>
</fullquery>

 
<fullquery name="attribute::exists_p.attr_exists_p">      
      <querytext>
      
	select case when exists (select 1 
                                   from acs_attributes a
                                  where (a.attribute_name = :attribute
                                         or a.column_name = :attribute)
                                    and a.object_type = :object_type)
                    then 1
                    else 0
                    end
          
    
      </querytext>
</fullquery>

 
<fullquery name="attribute::array_for_type.select_attributes">      
      <querytext>

	select coalesce(a.column_name, a.attribute_name) as name, 
               a.pretty_name, a.attribute_id, a.datatype, 
               v.enum_value, v.pretty_name as value_pretty_name
	from acs_object_type_attributes a left outer join
               acs_enum_values v using (attribute_id),
               (select t.object_type,
		       tree_level(tree_sortkey) -
		         (select tree_level(tree_sortkey) from acs_object_types where object_type = :start_with) as type_level
                  from acs_object_types t
		 where tree_sortkey like (select tree_sortkey from acs_object_types where object_type = :start_with) || '%') t
         where a.object_type = :object_type
           and t.object_type = a.ancestor_type $storage_clause
        order by type_level, a.sort_order
    
      </querytext>
</fullquery>

 
<fullquery name="attribute::multirow.attribute_select">      
      <querytext>	

	select *
	  from ($package_object_view) dummy
	 where object_id = :object_id

      </querytext>
</fullquery>

 
</queryset>
