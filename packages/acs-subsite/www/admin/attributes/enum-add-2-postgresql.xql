<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="insert_enum_value">      
      <querytext>
      
		    insert into acs_enum_values
		    (attribute_id, sort_order, enum_value, pretty_name)
		    select :attribute_id, :sort_order, :pretty_name, :pretty_name
		    
		    where not exists (select 1 
                                        from acs_enum_values v2
                                       where v2.pretty_name = :pretty_name
                                         and v2.attribute_id = :attribute_id)
		
      </querytext>
</fullquery>

 
</queryset>
