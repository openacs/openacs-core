<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="drop_role">
<querytext>
begin acs_rel_type.drop_role(:role);end;
</querytext>
</fullquery>

<fullquery name="role_used_p">      
      <querytext>
      
		select case when exists (select 1 from acs_rel_types where role_one = :role or role_two = :role) then 1 else 0 end
		from dual
	    
      </querytext>
</fullquery>

 
</queryset>
