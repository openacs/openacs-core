<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="attribute_for_dynamic_object_p">      
      <querytext>
      
	select case when exists (select 1 
                                   from acs_attributes a, acs_object_types t
                                  where t.dynamic_p = 't'
                                    and a.object_type = t.object_type
                                    and a.attribute_id = :value)
	            then 1 else 0 end
	  from dual
    
      </querytext>
</fullquery>

 
<fullquery name="exists_p.attr_exists_p">      
      <querytext>
      
	select case when exists (select 1 
                                   from acs_attributes a
                                  where (a.attribute_name = :attribute
                                         or a.column_name = :attribute)
                                    and a.object_type = :object_type)
                    then 1
                    else 0
                    end
          from dual
    
      </querytext>
</fullquery>

 
<fullquery name="delete.select_attr_info">      
      <querytext>
      
        select a.object_type, a.attribute_name, 
               case when a.storage = 'type_specific' then t.table_name else a.table_name end as table_name,
	       nvl(a.column_name, a.attribute_name) as column_name
          from acs_attributes a, acs_object_types t
         where a.attribute_id = :attribute_id
           and t.object_type = a.object_type
    
      </querytext>
</fullquery>

 
<fullquery name="array_for_type.select_attributes">      
      <querytext>
      
	select nvl(a.column_name, a.attribute_name) as name, 
               a.pretty_name, a.attribute_id, a.datatype, 
               v.enum_value, v.pretty_name as value_pretty_name
	from acs_object_type_attributes a,
               acs_enum_values v,
               (select t.object_type, level as type_level
                  from acs_object_types t
                 start with t.object_type = :start_with
               connect by prior t.object_type = t.supertype) t 
         where a.object_type = :object_type
           and a.attribute_id = v.attribute_id(+)
           and t.object_type = a.ancestor_type $storage_clause
        order by type_level, a.sort_order
    
      </querytext>
</fullquery>

 
</queryset>
