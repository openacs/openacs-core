<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="role_used_p">      
      <querytext>
      
		select case when exists (select 1 from acs_rel_types where role_one = :role or role_two = :role) then 1 else 0 end
		
	    
      </querytext>
</fullquery>

 
</queryset>
