<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="rel_type_dynamic_p">      
      <querytext>
      
	select case when exists (select 1 
                                   from acs_object_types t
                                  where t.dynamic_p = 't'
                                    and t.object_type = :value)
	            then 1 else 0 end
	  from dual
    
      </querytext>
</fullquery>

 
</queryset>
