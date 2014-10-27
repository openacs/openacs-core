<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

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
 
<fullquery name="apm_specific_version_dependencies">      
  <querytext>
    select t.pretty_name dep_pretty_name, v.version_name dep_version_name,
      v.version_id dep_version_id, d.dependency_type as dep_type
    from apm_package_versions v, apm_package_dependencies d, apm_package_types t
    where d.service_uri = :service_uri
      and d.dependency_type in ($other_dependency_in)
      and d.version_id = v.version_id
      and t.package_key = v.package_key 
      and apm_package_version.sortable_version_name(d.service_version)
        $sign apm_package_version.sortable_version_name(:service_version)
      </querytext>
</fullquery>

</queryset>
