<?xml version="1.0"?>
<queryset>

<fullquery name="apm_package_info_by_version_id">      
      <querytext>
      
    select package_key, pretty_name, version_name, installed_p 
    from apm_package_version_info 
    where version_id = :version_id

      </querytext>
</fullquery>

 
<fullquery name="apm_all_dependencies">      
      <querytext>
      
	select dependency_id, service_uri, service_version
	from   apm_package_dependencies
	where  version_id = :version_id
	and    dependency_type = :dependency_type_prep
	order by service_uri
    
      </querytext>
</fullquery>

</queryset>
