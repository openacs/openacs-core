<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="rel_type_dynamic_p">      
      <querytext>
      
	select case when exists (select 1 
                                   from acs_object_types t
                                  where t.dynamic_p = 't'
                                    and t.object_type = :value)
	            then 1 else 0 end
	  
    
      </querytext>
</fullquery>

 
</queryset>
