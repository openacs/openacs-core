<?xml version="1.0"?>
<queryset>

<fullquery name="select_role_props">      
      <querytext>
      
    select r.pretty_name, r.pretty_plural
      from acs_rel_roles r 
     where r.role = :role

      </querytext>
</fullquery>

 
<fullquery name="update_role">      
      <querytext>
      
	update acs_rel_roles r
	   set r.pretty_name = :pretty_name,
	       r.pretty_plural = :pretty_plural
	 where r.role = :role
    
      </querytext>
</fullquery>

 
</queryset>
