<?xml version="1.0"?>
<queryset>

<fullquery name="new.package_select">      
      <querytext>
      
	    select t.package_name, lower(t.id_column) as id_column
	      from acs_object_types t
	     where t.object_type = :party_type
	
      </querytext>
</fullquery>

 
</queryset>
