<?xml version="1.0"?>
<queryset>

<fullquery name="new.group_name_query">      
      <querytext>
      
		select substr(instance_name, 1, 90)
		from apm_packages
		where package_id = :package_id
	    
      </querytext>
</fullquery>

 
</queryset>
