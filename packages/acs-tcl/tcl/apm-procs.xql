<?xml version="1.0"?>
<queryset>

<fullquery name="apm_package_version_enabled_p.apm_package_version_installed_p">
      <querytext>

	select case when count(*) = 0 then 0 else 1 end from apm_package_versions
	where version_id = :version_id
	and enabled_p = 't'
      </querytext>
</fullquery>

<fullquery name="apm_mark_version_for_reload.package_key_select">      
      <querytext>
      select package_key from apm_package_version_info where version_id = :version_id
      </querytext>
</fullquery>

 
<fullquery name="apm_mark_version_for_reload.file_info">      
      <querytext>
      
        select file_id, path
        from   apm_package_files
        where  version_id = :version_id
        and    file_type in ('tcl_procs', 'query_file')
        and    (db_type is null or db_type = '[db_type]')
        order by path
    
      </querytext>
</fullquery>

 
<fullquery name="apm_mark_version_for_reload.package_key_select">      
      <querytext>
      
        select package_key
        from apm_package_version_info
        where version_id = :version_id
    
      </querytext>
</fullquery>

<fullquery name="apm_parameter_register.apm_parameter_cache_update">      
      <querytext>

	select v.package_id, p.parameter_name, 
               coalesce(p.default_value, v.attr_value) as attr_value
	from apm_parameters p left outer join apm_parameter_values v
             using (parameter_id)
	where p.package_key = :package_key
    
      </querytext>
</fullquery>

<fullquery name="apm_load_libraries.apm_enabled_packages">      
      <querytext>
      
	select distinct package_key
	from apm_package_versions
	where enabled_p='t'
    
      </querytext>
</fullquery>

 
<fullquery name="apm_load_libraries.apm_enabled_packages">      
      <querytext>
      
	select distinct package_key
	from apm_package_versions
	where enabled_p='t'
    
      </querytext>
</fullquery>

 
<fullquery name="apm_load_queries.apm_enabled_packages">      
      <querytext>

      select distinct package_key
	from apm_package_versions
	where enabled_p='t'
      </querytext>
</fullquery>

 
<fullquery name="apm_pretty_name_for_file_type.pretty_name_select">      
      <querytext>
      
        select pretty_name
        from apm_package_file_types
        where file_type_key = :type
    
      </querytext>
</fullquery>

 
<fullquery name="apm_pretty_name_for_db_type.pretty_db_name_select">      
      <querytext>
      
        select pretty_db_name
        from apm_package_db_types
        where db_type_key = :db_type
    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_parameters.get_names">      
      <querytext>
      
	select parameter_name from apm_parameters
	where package_key = :package_key
    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_registered_p.apm_package_registered_p">      
      <querytext>
      
	select 1 from apm_package_types 
	where package_key = :package_key
    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_installed_p.apm_package_installed_p">      
      <querytext>
      
	select 1 from apm_package_versions
	where package_key = :package_key
	and installed_p = 't'
    
      </querytext>
</fullquery>

 
<fullquery name="apm_version_installed_p.apm_version_installed_p">      
      <querytext>
      
	select 1 from apm_package_versions
	where version_id = :version_id
	and installed_p = 't'
    
      </querytext>
</fullquery>

 
<fullquery name="apm_parameter_update.parameter_update">      
      <querytext>
      
       update apm_parameters 
	set parameter_name = :parameter_name,
            default_value  = :default_value,
            datatype       = :datatype, 
	    description	   = :description,
	    section_name   = :section_name,
            min_n_values   = :min_n_values,
            max_n_values   = :max_n_values
      where parameter_id = :parameter_id
    
      </querytext>
</fullquery>

 
<fullquery name="apm_parameter_unregister.all_parameters_packages">      
      <querytext>
      
	select package_id, parameter_id, parameter_name 
	from apm_packages p, apm_parameters ap
	where p.package_key = ap.package_key
	and ap.parameter_id = :parameter_id

    
      </querytext>
</fullquery>

  
<fullquery name="apm_package_key_from_id_mem.apm_package_key_from_id">      
      <querytext>
      
	select package_key from apm_packages where package_id = :package_id
    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_id_from_key_mem.apm_package_id_from_key">      
      <querytext>
      
	select package_id from apm_packages where package_key = :package_key
    
      </querytext>
</fullquery>

 
<fullquery name="apm_version_info.apm_package_by_version_id">      
      <querytext>
      
	    select pretty_name, version_name, package_key, installed_p, distribution_uri, tagged_p
	    from apm_package_version_info where version_id = :version_id
	
      </querytext>
</fullquery>

 
<fullquery name="apm_parameter_sync.apm_parameter_names_and_values">      
      <querytext>
      
	select parameter_name, attr_value
	from apm_parameters p, apm_parameter_values v, apm_packages a
	where p.parameter_id = v.parameter_id
	and a.package_id = v.package_id
	and a.package_id = :package_id
    
      </querytext>
</fullquery>

 
</queryset>
