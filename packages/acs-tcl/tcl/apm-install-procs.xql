<?xml version="1.0"?>
<queryset>
 
<fullquery name="apm_dependency_provided_p.get_service_versions">
      <querytext>
      
	select service_version
	from apm_package_dependencies d, apm_package_types a, apm_package_versions v
	where d.dependency_type = 'provides'
	and d.version_id = v.version_id
	and d.service_uri = :dependency_uri
	and v.installed_p = 't'
	and a.package_key = v.package_key
    
      </querytext>
</fullquery>
  
<fullquery name="apm_package_deinstall.apm_uninstall_record">      
      <querytext>
      
	update apm_package_versions
	set    installed_p = 'f', enabled_p = 'f'
	where package_key = :package_key
    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_version_count.apm_package_version_count">      
      <querytext>
      
	select count(*) from apm_package_versions
	where package_key = :package_key
    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_upgrade_parameters.parameter_id_get">      
      <querytext>
      
	    select parameter_id from apm_parameters
	    where parameter_name = :parameter_name
	    and package_key = :package_key
	
      </querytext>
</fullquery>

 
<fullquery name="apm_package_install_dependencies.all_dependencies_for_version">      
      <querytext>
      
	select dependency_id from apm_package_dependencies
	where version_id = :version_id
    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_install_owners.apm_delete_owners">      
      <querytext>
      
	delete from apm_package_owners where version_id = :version_id
    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_install_owners.owner_insert">      
      <querytext>
      
	    insert into apm_package_owners(version_id, owner_uri, owner_name, sort_key)
	    values(:version_id, :owner_uri, :owner_name, :counter)
	
      </querytext>
</fullquery>

<fullquery name="apm_package_install_spec.package_version_info_select">      
      <querytext>
      
	select package_key, version_id
	from apm_package_version_info 
	where version_id = :version_id
    
      </querytext>
</fullquery>
 
<fullquery name="apm_package_install_spec.apm_spec_file_register">      
      <querytext>
      
	    update apm_package_types
		set spec_file_path = :path
	        where package_key = :package_key
	
      </querytext>
</fullquery>

<fullquery name="apm_package_install_callbacks.delete_all_callbacks">
      <querytext>
        delete from apm_package_callbacks
        where version_id = :version_id
      </querytext>
</fullquery>

<fullquery name="apm_unregister_disinherited_params.get_parameter_ids">      
  <querytext>
    select ap.parameter_id
    from apm_parameters ap
    where ap.package_key = :package_key
      and exists (select 1
                  from apm_parameters ap2, apm_package_dependencies apd
                  where ap2.package_key = apd.service_uri
                    and ap2.parameter_name = ap.parameter_name
                    and apd.dependency_id = :dependency_id)
  </querytext>
</fullquery>

<fullquery name="apm_copy_param_to_descendents.param">      
  <querytext>
    select ap.*
    from apm_parameters ap
    where package_key = :new_package_key
      and parameter_name = :parameter_name
  </querytext>
</fullquery>

<fullquery name="apm_copy_inherited_params.inherited_params">      
  <querytext>
    select ap.*
    from apm_parameters ap
    where package_key = :inherited_package_key
      and scope = 'instance'
   </querytext>
</fullquery>
 
</queryset>
