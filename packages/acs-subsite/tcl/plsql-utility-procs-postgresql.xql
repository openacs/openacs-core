<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="object_type_exists_p.object_type_exists_p">      
      <querytext>
      
	    select case when exists (select 1 from acs_object_types where object_type=:object_type)
                        then 1
                        else 0
                   end
              
	
      </querytext>
</fullquery>

 
</queryset>
