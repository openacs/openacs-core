<?xml version="1.0"?>
<queryset>

<fullquery name="apm_dependency_doubleclick_check">      
      <querytext>
      
	select count(*) from apm_package_dependencies
	where dependency_id = :dependency_id
    
      </querytext>
</fullquery>

 
</queryset>
