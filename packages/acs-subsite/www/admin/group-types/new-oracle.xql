<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="pretty_name_unique">      
      <querytext>
	  select case when exists (select 1 from acs_object_types t where t.pretty_name = :pretty_name)
                 then 1 else 0 end
	  from dual
	
      </querytext>
</fullquery>
 
</queryset>
