<?xml version="1.0"?>
<queryset>

<fullquery name="version_select">      
      <querytext>
      
	select pretty_name, version_name, package_key
	from apm_package_version_info i
	where version_id = :version_id
    
      </querytext>
</fullquery>

 
</queryset>
