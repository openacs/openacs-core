<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="package_type_dynamic_p.object_type_dynamic_p">      
      <querytext>
      
	select case when exists (select 1 
                                   from acs_object_types t
                                  where t.dynamic_p = 't'
                                    and t.object_type = :object_type)
	            then 1 else 0 end
	  
    
      </querytext>
</fullquery>

 
<fullquery name="package_create_attribute_list.select_all_attributes">      
      <querytext>
      FIX ME CONNECT BY

	select upper(coalesce(attr.table_name,t.table_name)) as attr_table_name, 
	       upper(coalesce(attr.column_name, attr.attribute_name)) as attr_column_name, 
	       attr.ancestor_type, attr.min_n_values, attr.default_value
	  from acs_object_type_attributes attr, 
	       (select t.object_type, t.table_name, level as type_level
	          from acs_object_types t
	         start with t.object_type = :object_type
	       connect by prior t.supertype = t.object_type) t
         where attr.ancestor_type = t.object_type
           and attr.object_type = :object_type
        order by t.type_level 
    
      </querytext>
</fullquery>

 
<fullquery name="package_recreate_hierarchy.select_object_types">      
      <querytext>
      FIX ME CONNECT BY

	select t.object_type
	  from acs_object_types t
	 where t.dynamic_p = 't'
	 start with t.object_type = :object_type
       connect by prior t.object_type = t.supertype
    
      </querytext>
</fullquery>

 
<fullquery name="package_create.package_valid_p">      
      <querytext>
      
	    select case when exists (select 1 
                                       from user_objects 
                                      where status = 'INVALID'
                                        and object_name = upper(:package_name)
                                        and object_type = upper(:type))
                        then 0 else 1 end
	      
	
      </querytext>
</fullquery>

 
<fullquery name="package_object_view_reset.select_ancestor_types">      
      <querytext>
      FIX ME CONNECT BY

	select t.object_type as ancestor_type
	  from acs_object_types t 
	 start with t.object_type = :object_type 
       connect by prior t.supertype = t.object_type
    
      </querytext>
</fullquery>

 
<fullquery name="package_object_view_reset.select_sub_types">      
      <querytext>
      FIX ME CONNECT BY

	select t.object_type as sub_type
	  from acs_object_types t 
	 start with t.object_type = :object_type 
       connect by prior t.object_type = t.supertype
    
      </querytext>
</fullquery>

 
<fullquery name="package_insert_default_comment.select_comments">      
      <querytext>
      
	    select acs_object__name(:user_id) as author,
	           current_timestamp as creation_date
	      
	
      </querytext>
</fullquery>

 
<fullquery name="package_insert_default_comment.select_comments">      
      <querytext>
      
	    select acs_object__name(:user_id) as author,
	           current_timestamp as creation_date
	      
	
      </querytext>
</fullquery>

 
<fullquery name="package_object_attribute_list.attributes_select">      
      <querytext>

	select a.attribute_id, 
	       coalesce(a.table_name, t.table_name) as table_name,
	       coalesce(a.column_name, a.attribute_name) as attribute_name, 
	       a.pretty_name, 
	       a.datatype, 
	       case when a.min_n_values = 0 then 'f' else 't' end as required_p, 
               a.default_value, 
               t.table_name as object_type_table_name, 
               t.id_column as object_type_id_column
          from acs_object_type_attributes a, 
               (select t.object_type, t.table_name, t.id_column, tree_level(t.tree_sortkey) as type_level
                  from acs_object_types t
		 where tree_sortkey like
		         (select tree_sortkey || '%'
			    from acs_object_types
			   where object_type = :start_with)) t
         where a.object_type = :object_type
           and t.object_type = a.ancestor_type $storage_clause
         order by type_level
      </querytext>
</fullquery>

 
<fullquery name="package_table_columns_for_type.select_object_type_param_list">      
      <querytext>

	select cols.table_name, cols.column_name
	  from user_tab_columns cols, 
	       (select upper(t2.table_name) as table_name
	          from acs_object_types t1, acs_object_types t2
		 where t2.tree_sortkey <= t1.tree_sortkey
		   and t1.tree_sortkey like (t2.tree_sortkey || '%')
		   and t1.object_type = :object_type) t
	 where cols.column_name in
	          (select args.arg_name
                     from acs_function_args args
                    where args.function = upper(:package_name) || '__' || upper(:object_name))
	   and cols.table_name = t.table_name
    
      </querytext>
</fullquery>

 
<fullquery name="package_instantiate_object.create_object">      
      <querytext>

	select ${package_name}__new([plpgsql_utility::generate_attribute_parameter_call \
		-prepend ":" \
		${package_name}__new \
		$pieces])

      </querytext>
</fullquery>

 
</queryset>
