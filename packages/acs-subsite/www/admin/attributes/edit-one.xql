<?xml version="1.0"?>
<queryset>

<fullquery name="attribute_properties">      
      <querytext>
      
    select a.pretty_name as attribute_pretty_name, a.datatype, a.attribute_id,
           coalesce(a.column_name,a.attribute_name) as attribute_column,
           t.id_column as type_column, t.table_name as type_table, t.object_type,
           a.min_n_values
      from acs_attributes a, acs_object_types t
     where a.attribute_id = :attribute_id
       and a.object_type = t.object_type

      </querytext>
</fullquery>

 
<fullquery name="select_value">      
      <querytext>
      
    select my_view.$attribute_column as current_value
      from ([package_object_view $object_type]) my_view
     where my_view.object_id = :id_column

      </querytext>
</fullquery>

 
<fullquery name="select_enum_values">      
      <querytext>
      
	select enum.pretty_name, enum.enum_value
	  from acs_enum_values enum
	 where enum.attribute_id = :attribute_id 
	 order by enum.sort_order
    
      </querytext>
</fullquery>

 
<fullquery name="attribute_update">      
      <querytext>
      update $type_table 
                set $attribute_column = :attribute_value 
              where $type_column = :id_column
      </querytext>
</fullquery>

 
</queryset>
