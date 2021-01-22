<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="object_type_exists_p.object_type_exists_p">      
      <querytext>
      
	    select case when exists (select 1 from acs_object_types where object_type=:object_type)
                        then 1
                        else 0
                   end
              from dual
	
      </querytext>
</fullquery>

 
</queryset>
