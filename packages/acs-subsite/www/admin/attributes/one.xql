<?xml version="1.0"?>
<queryset>

<fullquery name="select_attribute_info">      
      <querytext>
      
    select a.attribute_id, a.object_type, a.table_name, a.attribute_name, 
           a.pretty_name, a.pretty_plural, a.sort_order, a.datatype, 
           a.default_value, a.min_n_values, a.max_n_values, a.storage, 
           a.static_p, a.column_name, t.dynamic_p
     from acs_attributes a, acs_object_types t
    where a.object_type = t.object_type
      and a.attribute_id = :attribute_id

      </querytext>
</fullquery>

 
<fullquery name="enum_values">      
      <querytext>
      
	select v.enum_value, v.pretty_name
	  from acs_enum_values v
	 where v.attribute_id = :attribute_id
	 order by v.sort_order
    
      </querytext>
</fullquery>

 
</queryset>
