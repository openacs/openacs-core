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
          
    
      </querytext>
</fullquery>

 
</queryset>
