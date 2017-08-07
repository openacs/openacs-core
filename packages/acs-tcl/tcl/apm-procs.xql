<?xml version="1.0"?>
<queryset>

  <fullquery name="apm_one_package_descendents.get_descendents">
    <querytext>
      select apv.package_key
      from apm_package_versions apv, apm_package_dependencies apd
      where apd.version_id = apv.version_id
        and apv.enabled_p = 't'
        and apd.dependency_type in ('extends', 'embeds')
        and apd.service_uri = :package_key
    </querytext>
  </fullquery>

  <fullquery name="apm_build_subsite_packages_list.get_subsites">
    <querytext>
      select package_key
      from apm_package_types
      where implements_subsite_p = 't'
    </querytext>
  </fullquery>

  <fullquery name="apm_package_list_url_resolution.get_inherit_templates_p">
    <querytext>
      select inherit_templates_p
      from apm_package_types
      where package_key = :package_key
    </querytext>
  </fullquery>

  <fullquery name="apm_package_list_url_resolution.get_dependencies">
    <querytext>
      select apd.service_uri, apd.dependency_type
      from apm_package_versions apv, apm_package_dependencies apd
      where apv.package_key = :package_key
        and apv.installed_p = 't'
        and apd.version_id = apv.version_id
        and (apd.dependency_type = 'embeds'
             or apd.dependency_type =  'extends' and :inherit_templates_p = 't')
      order by apd.dependency_id
    </querytext>
  </fullquery>

  <fullquery name="apm_one_package_inherit_order.get_dependencies">
    <querytext>
      select apd.service_uri
      from apm_package_versions apv, apm_package_dependencies apd
      where apv.package_key = :package_key
        and apv.installed_p = 't'
        and apd.version_id = apv.version_id
        and apd.dependency_type in ('extends', 'embeds')
      order by apd.dependency_id desc
    </querytext>
  </fullquery>

  <fullquery name="apm_one_package_load_libraries_dependencies.get_dependencies">
    <querytext>
      select apd.service_uri
      from apm_package_versions apv, apm_package_dependencies apd
      where apv.package_key = :package_key
        and apv.installed_p = 't'
        and apd.version_id = apv.version_id
        and apd.dependency_type in ('requires', 'embeds', 'extends')
      order by apd.dependency_id desc
    </querytext>
  </fullquery>

  <fullquery name="apm_package_version_enabled_p.apm_package_version_enabled_p">
    <querytext>
      select case when count(*) = 0 then 0 else 1 end from apm_package_versions
      where version_id = :version_id
      and enabled_p = 't'
    </querytext>
  </fullquery>

  <fullquery name="apm_parameter_register.apm_parameter_cache_update">      
    <querytext>
      select coalesce(v.package_id, 0) as package_id, p.parameter_name, 
      case when v.value_id is null then p.default_value else v.attr_value end as attr_value
      from apm_parameters p left outer join apm_parameter_values v
      using (parameter_id)
      where p.package_key = :package_key
    </querytext>
  </fullquery>

  <fullquery name="apm_enabled_packages.enabled_packages">      
    <querytext>
      select distinct package_key
      from apm_package_versions
      where enabled_p='t'
      order by package_key
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
  
  <fullquery name="apm_package_enabled_p.apm_package_enabled_p">      
    <querytext>
      select 1 from apm_package_versions
      where package_key = :package_key
      and enabled_p = 't'
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
  
  <fullquery name="apm_parameter_update.object_title_update">      
    <querytext>
	update acs_objects
	set title = :parameter_name
	where object_id = :parameter_id
    </querytext>
  </fullquery>
  
  <fullquery name="apm_parameter_unregister.select_parameter_id">      
    <querytext>
      select parameter_id
      from apm_parameters
      where package_key = :package_key
        and parameter_name = :parameter
    </querytext>
  </fullquery>
  
  <fullquery name="apm_parameter_unregister.get_scope_and_name">      
    <querytext>
      select scope, parameter_name
      from apm_parameters
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
      select package_key
      from apm_packages
      where package_id = :package_id
    </querytext>
  </fullquery>

  <fullquery name="apm_version_id_from_package_key.get_enabled_id">      
    <querytext>
        select version_id 
        from apm_enabled_package_versions 
        where package_key = :package_key
    </querytext>
  </fullquery>
  
  <fullquery name="apm_version_id_from_package_key.get_id">      
    <querytext>
        select version_id 
        from apm_package_versions 
        where package_key = :package_key
    </querytext>
  </fullquery>
  
  <fullquery name="apm_package_id_from_key_mem.apm_package_id_from_key">      
    <querytext>
      select package_id
      from apm_packages
      where package_key = :package_key
    </querytext>
  </fullquery>
  
  <fullquery name="apm_version_info.apm_package_by_version_id">      
    <querytext>
      select pretty_name, version_name, package_key, installed_p, distribution_uri, tagged_p
      from   apm_package_version_info
      where  version_id = :version_id
    </querytext>
  </fullquery>

  <fullquery name="apm_package_rename.nodes_to_sync">      
    <querytext>
      select node_id
      from site_nodes
      where object_id = :package_id
    </querytext>
  </fullquery>
  
  <fullquery name="apm_parameter_sync.apm_parameter_names_and_values">      
    <querytext>
      select parameter_name, attr_value
      from apm_parameters p, apm_parameter_values v, apm_packages a
      where p.scope = 'instance'
      and p.parameter_id = v.parameter_id
      and a.package_id = v.package_id
      and a.package_id = :package_id
    </querytext>
  </fullquery>

  <fullquery name="apm_get_callback_proc.select_proc">      
    <querytext>
        select proc
        from apm_package_callbacks
        where version_id = :version_id
        and   type = :type
    </querytext>
  </fullquery>

  <fullquery name="apm_set_callback_proc.insert_proc">      
    <querytext>
        insert into apm_package_callbacks
          (version_id, type, proc)
        values (:version_id, :type, :proc)
    </querytext>
  </fullquery>  

  <fullquery name="apm_set_callback_proc.update_proc">      
    <querytext>
        update apm_package_callbacks
                set proc = :proc
        where version_id = :version_id
          and type = :type
    </querytext>
  </fullquery>  

  <fullquery name="apm_remove_callback_proc.delete_proc">      
    <querytext>
        delete from apm_package_callbacks
        where version_id = (select version_id 
                            from apm_enabled_package_versions 
                            where package_key = :package_key)
        and   type = :type
    </querytext>
  </fullquery>  

  <fullquery name="apm_version_get.select_version_info">      
    <querytext>
        select v.version_id,
               v.package_key,
               v.version_name,
               v.version_uri,
               v.summary,
               v.description_format,
               v.description,
               to_char(v.release_date, 'YYYY-MM-DD') as release_date,
               v.vendor,
               v.vendor_uri,
               v.enabled_p,
               v.installed_p,
               v.tagged_p,
               v.imported_p,
               v.data_model_loaded_p,
               v.cvs_import_results,
               v.activation_date,
               v.deactivation_date,
               v.item_id,
               v.content_length,
               v.distribution_uri,
               v.distribution_date,
               v.auto_mount,
               t.pretty_name,
               t.pretty_plural
        from   apm_package_versions v,
               apm_package_types t
        where  v.version_id = :version_id
        and    t.package_key = v.package_key
    </querytext>
  </fullquery>  

  <fullquery name="apm::get_package_descendent_options.get">      
    <querytext>
      select pretty_name, package_key
      from apm_package_types
      where implements_subsite_p = 't'
        and package_key in ($in_clause)
      order by pretty_name
    </querytext>
  </fullquery>  

  <fullquery name="apm::convert_type.update_package_key">      
    <querytext>
      update apm_packages
      set package_key = :new_package_key
      where package_id = :package_id
    </querytext>
  </fullquery>  

  <fullquery name="apm::convert_type.get_params">      
    <querytext>
      select parameter_name, parameter_id
      from apm_parameters
      where package_key = :old_package_key
    </querytext>
  </fullquery>  

  <fullquery name="apm::convert_type.get_new_parameter_id">      
    <querytext>
      select parameter_id as new_parameter_id
      from apm_parameters
      where package_key = :new_package_key
        and parameter_name = :parameter_name
    </querytext>
  </fullquery>  

  <fullquery name="apm::convert_type.update_param">      
    <querytext>
      update apm_parameter_values
      set parameter_id = :new_parameter_id
      where parameter_id = :parameter_id
        and package_id = :package_id
    </querytext>
  </fullquery>  

</queryset>
