<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="apm_package_install_version.version_insert">      
      <querytext>
		select apm_package_version__new(
			:version_id,
			:package_key,
			:version_name,
			:version_uri,
			:summary,
			:description_format,
			:description,
			:release_date,
			:vendor,
			:vendor_uri,
                        :auto_mount,
			't',
			't'
	              );
      </querytext>
</fullquery>

 
<fullquery name="apm_package_delete.apm_package_delete">      
      <querytext>

	    select apm_package_type__drop_type(
	        :package_key,
	        't'
            );
    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_version_delete.apm_version_delete">      
      <querytext>

	 select apm_package_version__delete(:version_id);	 
    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_install_spec.version_mark_installed">      
      <querytext>

            update apm_package_versions
            set    installed_p = (version_id = :version_id)
            where  package_key = :package_key
        
      </querytext>
</fullquery>

 
<fullquery name="apm_version_disable.apm_package_version_disable">      
      <querytext>

	  select apm_package_version__disable(
            :version_id
	  );
    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_register.application_register">      
      <querytext>

	    select apm__register_application (
		        :package_key,
			:pretty_name,
			:pretty_plural,
			:package_uri,
			:initial_install_p,
			:singleton_p,
                        :implements_subsite_p,
                        :inherit_templates_p,
			:spec_file_path,
			:spec_file_mtime
          		);
	
      </querytext>
</fullquery>

 
<fullquery name="apm_package_register.service_register">      
      <querytext>

	    select apm__register_service (
			:package_key,
			:pretty_name,
			:pretty_plural,
			:package_uri,
			:initial_install_p,
			:singleton_p,
                        :implements_subsite_p,
                        :inherit_templates_p,
			:spec_file_path,
			:spec_file_mtime
			);
	
      </querytext>
</fullquery>

 
<fullquery name="apm_version_update.apm_version_update">      
      <querytext>

	select apm_package_version__edit(
                                 null,
				 :version_id, 
				 :version_name, 
				 :version_uri,
				 :summary,
				 :description_format,
				 :description,
				 :release_date,
				 :vendor,
				 :vendor_uri,
                                 :auto_mount,
				 't',
				 't'				 
				 );
    
      </querytext>
</fullquery>

 
<fullquery name="apm_version_upgrade.apm_version_upgrade">      
      <querytext>

	    select apm_package_version__upgrade(:version_id);
    
      </querytext>
</fullquery>

 
<fullquery name="apm_upgrade_for_version_p.apm_upgrade_for_version_p">      
      <querytext>

	    select apm_package_version__upgrade_p(
	              :path,
	              :initial_version_name,
	              :final_version_name
	          );
    
      </querytext>
</fullquery>


<fullquery name="apm_upgrade_script_compare.test_f1">
      <querytext>

	    select apm_package_version__sortable_version_name(:f1_version_from);

      </querytext>
</fullquery>


<fullquery name="apm_upgrade_script_compare.test_f2">
      <querytext>

	    select apm_package_version__sortable_version_name(:f2_version_from);

      </querytext>
</fullquery>

 <fullquery name="apm_dependency_provided_p.apm_dependency_check">      
      <querytext>
      
	select apm_package_version__version_name_greater(service_version, :dependency_version) as version_p
	from apm_package_dependencies d, apm_package_types a, apm_package_versions v
	where d.dependency_type = 'provides'
	and d.version_id = v.version_id
	and d.service_uri = :dependency_uri
	and v.installed_p = 't'
	and a.package_key = v.package_key
    
      </querytext>
</fullquery>

 <fullquery name="apm_dependency_provided_p.version_greater_p">      
      <querytext>
        select apm_package_version__version_name_greater(:provided_version, :dependency_version)
      </querytext>
</fullquery>

<fullquery name="apm_copy_param_to_descendents.param_exists">      
  <querytext>
    select apm__parameter_p(:descendent_package_key, :parameter_name);
  </querytext>
</fullquery>

<fullquery name="apm_copy_param_to_descendents.copy_descendent_param">      
  <querytext>
    select apm__register_parameter(null, :descendent_package_key, :parameter_name,
                                   :description, :scope, :datatype, :default_value,
                                   :section_name, :min_n_values, :max_n_values)
  </querytext>
</fullquery>

<fullquery name="apm_copy_inherited_params.param_exists">      
  <querytext>
    select apm__parameter_p(:new_package_key, :parameter_name);
  </querytext>
</fullquery>

<fullquery name="apm_copy_inherited_params.copy_inherited_param">      
  <querytext>
    select apm__register_parameter(null, :new_package_key, :parameter_name, :description,
                                   :scope, :datatype, :default_value, :section_name,
                                   :min_n_values, :max_n_values)
  </querytext>
</fullquery>

<fullquery name="apm_package_upgrade_p.apm_package_upgrade_p">      
      <querytext>
      
	select apm_package_version__version_name_greater(:version_name, version_name) as upgrade_p
	from apm_package_versions
	where package_key = :package_key
	and version_id = apm_package__highest_version (:package_key)
    
      </querytext>
</fullquery>

<fullquery name="apm_version_enable.apm_package_version_enable">      
      <querytext>

	  select apm_package_version__enable(
            :version_id
	  );
    
      </querytext>
</fullquery>

<fullquery name="apm_package_upgrade_from.apm_package_upgrade_from">      
      <querytext>
      
	    select version_name from apm_package_versions
	    where package_key = :package_key
	    and version_id = apm_package__highest_version(:package_key)
	
      </querytext>
</fullquery>

<fullquery name="apm_version_names_compare.select_sortable_versions">      
      <querytext>
      
	    select apm_package_version__sortable_version_name(:version_name_1) as sortable_version_1,
                   apm_package_version__sortable_version_name(:version_name_2) as sortable_version_2
            from   dual

      </querytext>
</fullquery>

<fullquery name="apm_version_sortable.sortable_version">
      <querytext>
	    select apm_package_version__sortable_version_name(:version)
      </querytext>
</fullquery>

</queryset>
