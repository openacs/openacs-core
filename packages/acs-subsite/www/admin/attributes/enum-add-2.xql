<?xml version="1.0"?>
<queryset>

<fullquery name="select_max_sort_order">      
      <querytext>
      
    select coalesce(max(v.sort_order),0)
      from acs_enum_values v
     where v.attribute_id = :attribute_id

      </querytext>
</fullquery>

 
<fullquery name="delete_enum_value">      
      <querytext>
      
		delete from acs_enum_values 
		 where attribute_id = :attribute_id 
		   and sort_order = :sort_order
	    
      </querytext>
</fullquery>

 
<fullquery name="update_enum_value">      
      <querytext>
      
		update acs_enum_values
		   set pretty_name = :pretty_name
		 where attribute_id = :attribute_id
		   and sort_order = :sort_order
	    
      </querytext>
</fullquery>


<fullquery name="insert_enum_value">      
      <querytext>
      
		    insert into acs_enum_values
		    (attribute_id, sort_order, enum_value, pretty_name)
		    select :attribute_id, :sort_order, :pretty_name, :pretty_name
		    from dual
		    where not exists (select 1 
                                        from acs_enum_values v2
                                       where v2.pretty_name = :pretty_name
                                         and v2.attribute_id = :attribute_id)
		
      </querytext>
</fullquery>
 
</queryset>
