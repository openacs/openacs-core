<?xml version="1.0"?>
<queryset>

<fullquery name="attribute::add.select_table">      
      <querytext>
      
        select t.table_name
          from acs_object_types t
         where t.object_type = :object_type
    
      </querytext>
</fullquery>

 
<fullquery name="attribute::add.select_attribute_id">      
      <querytext>
      
        select a.attribute_id
          from acs_attributes a
         where a.object_type = :object_type
           and a.attribute_name = :attribute_name
    
      </querytext>
</fullquery>

 
<fullquery name="attribute::delete.select_attr_info">      
      <querytext>
      
        select a.object_type, a.attribute_name, 
               case when a.storage = 'type_specific' then t.table_name else a.table_name end as table_name,
	       coalesce(a.column_name, a.attribute_name) as column_name
          from acs_attributes a, acs_object_types t
         where a.attribute_id = :attribute_id
           and t.object_type = a.object_type
    
      </querytext>
</fullquery>

 
<fullquery name="attribute::value_delete.select_last_sort_order">      
      <querytext>
      
        select v.sort_order as old_sort_order
          from acs_enum_values v
         where v.attribute_id = :attribute_id
           and v.enum_value = :enum_value
    
      </querytext>
</fullquery>

 
<fullquery name="attribute::value_delete.delete_enum_value">      
      <querytext>
      
        delete from acs_enum_values v
        where v.attribute_id = :attribute_id
        and v.enum_value = :enum_value
    
      </querytext>
</fullquery>

 
<fullquery name="attribute::value_delete.update_sort_order">      
      <querytext>
      
            update acs_enum_values v
               set v.sort_order = v.sort_order - 1
             where v.attribute_id = :attribute_id
               and v.sort_order > :old_sort_order
        
      </querytext>
</fullquery>

 
<fullquery name="attribute::multirow.object_type_query">      
      <querytext>
      
	    select object_type from acs_objects where object_id = :object_id
	
      </querytext>
</fullquery>

 
<fullquery name="attribute::multirow.attribute_select">      
      <querytext>
      
        select * 
          from ($package_object_view) 
         where object_id = :object_id
	
      </querytext>
</fullquery>

 
<fullquery name="attribute::add_form_elements.select_enum_values">      
      <querytext>
      
		select enum.pretty_name, enum.enum_value
		from acs_enum_values enum
		where enum.attribute_id = :attribute_id 
		order by enum.sort_order
	    
      </querytext>
</fullquery>


<fullquery name="attribute::value_add.insert_enum_value">
<querytext>
	insert into acs_enum_values
	(attribute_id, sort_order, enum_value, pretty_name)
	select :attribute_id, :sort_order, :enum_value, :enum_value
	from dual
	where not exists (select 1 
	from acs_enum_values v2
	where v2.pretty_name = :enum_value
	and v2.attribute_id = :attribute_id)
</querytext>
</fullquery>
 
</queryset>
