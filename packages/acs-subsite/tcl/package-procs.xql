<?xml version="1.0"?>
<queryset>

<fullquery name="package_create_attribute_list.select_type_info">      
      <querytext>
      
	    select t.table_name as table, t.id_column as column
	      from acs_object_types t
	     where t.object_type = :object_type
	
      </querytext>
</fullquery>

 
<fullquery name="package_create_attribute_list.select_all_attributes">      
      <querytext>
      
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
      
	select t.object_type
	  from acs_object_types t
	 where t.dynamic_p = 't'
	 start with t.object_type = :object_type
       connect by prior t.object_type = t.supertype
    
      </querytext>
</fullquery>

 
<fullquery name="package_create.select_package_name">      
      <querytext>
      
	select t.package_name
	  from acs_object_types t
	 where t.object_type = :object_type
    
      </querytext>
</fullquery>

 
<fullquery name="package_create_attribute_list.select_type_info">      
      <querytext>
      
	select t.table_name, t.id_column, lower(t.package_name) as package_name, t.supertype
	  from acs_object_types t
	 where t.object_type = :object_type
    
      </querytext>
</fullquery>

 
<fullquery name="package_create_attribute_list.select_type_info">      
      <querytext>
      
	select t.table_name, t.id_column, lower(t.package_name) as package_name, t.supertype
	  from acs_object_types t
	 where t.object_type = :object_type
    
      </querytext>
</fullquery>

 
<fullquery name="package_create_attribute_list.select_type_info">      
      <querytext>
      
	select t.table_name, t.id_column, lower(t.package_name) as package_name, t.supertype
	  from acs_object_types t
	 where t.object_type = :object_type
    
      </querytext>
</fullquery>

 
<fullquery name="package_generate_body.select_supertype_function_params">      
      <querytext>
      
	select args.argument_name
	  from user_arguments args
         where args.package_name =upper(:supertype_package_name)
	   and args.object_name='NEW'
    
      </querytext>
</fullquery>

 
<fullquery name="package_object_view_reset.select_ancestor_types">      
      <querytext>
      
	select t.object_type as ancestor_type
	  from acs_object_types t 
	 start with t.object_type = :object_type 
       connect by prior t.supertype = t.object_type
    
      </querytext>
</fullquery>

 
<fullquery name="package_object_view_reset.select_sub_types">      
      <querytext>
      
	select t.object_type as sub_type
	  from acs_object_types t 
	 start with t.object_type = :object_type 
       connect by prior t.object_type = t.supertype
    
      </querytext>
</fullquery>

 
<fullquery name="package_create_attribute_list.select_type_info">      
      <querytext>
      
	select t.table_name, t.id_column, lower(t.package_name) as package_name, t.supertype
	  from acs_object_types t
	 where t.object_type = :object_type
    
      </querytext>
</fullquery>

 
<fullquery name="package_object_attribute_list.attributes_select">      
      <querytext>
--      FIX ME DECODE (USE SQL92 CASE) 
	select a.attribute_id, 
	       coalesce(a.table_name, t.table_name) as table_name,
	       coalesce(a.column_name, a.attribute_name) as attribute_name, 
	       a.pretty_name, 
	       a.datatype, 
	       decode(a.min_n_values,0,'f','t') as required_p, 
               a.default_value, 
               t.table_name as object_type_table_name, 
               t.id_column as object_type_id_column
          from acs_object_type_attributes a, 
               (select t.object_type, t.table_name, t.id_column, level as type_level
                  from acs_object_types t
                 start with t.object_type=:start_with
               connect by prior t.object_type = t.supertype) t 
         where a.object_type = :object_type
           and t.object_type = a.ancestor_type $storage_clause
         order by type_level
      </querytext>
</fullquery>

 
<fullquery name="package_create_attribute_list.select_type_info">      
      <querytext>
      
	select t.table_name, t.id_column, lower(t.package_name) as package_name, t.supertype
	  from acs_object_types t
	 where t.object_type = :object_type
    
      </querytext>
</fullquery>

 
<fullquery name="package_table_columns_for_type.select_object_type_param_list">      
      <querytext>
      
	select cols.table_name, cols.column_name
	  from user_tab_columns cols, 
	       (select upper(t.table_name) as table_name
	          from acs_object_types t
                 start with t.object_type = :object_type
               connect by prior t.supertype = t.object_type) t
	 where cols.column_name in
	          (select args.argument_name
                     from user_arguments args
                    where args.position > 0
	              and args.object_name = upper(:object_name)
	              and args.package_name = upper(:package_name))
	   and cols.table_name = t.table_name
    
      </querytext>
</fullquery>

 
<fullquery name="package_instantiate_object.package_select">      
      <querytext>
      
	    select t.package_name
	      from acs_object_types t
	     where t.object_type = :object_type
	
      </querytext>
</fullquery>

 
</queryset>
