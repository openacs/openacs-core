<?xml version="1.0"?>
<queryset>

<fullquery name="role_exists_p">      
      <querytext>
      
	select count(r.role) from acs_rel_roles r where r.role = :role
    
      </querytext>
</fullquery>

 
</queryset>
