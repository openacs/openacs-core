<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="apm_package_install_version.version_insert">      
      <querytext>
      
		begin
		:1 := apm_package_version.new(
			version_id => :version_id,
			package_key => :package_key,
			version_name => :version_name,
			version_uri => :version_uri,
			summary => :summary,
			description_format => :description_format,
			description => :description,
			release_date => :release_date,
			vendor => :vendor,
			vendor_uri => :vendor_uri,
                        auto_mount => :auto_mount,
			installed_p => 't',
			data_model_loaded_p => 't'
	              );
		end;
	    
      </querytext>
</fullquery>

<fullquery name="apm_package_install_version.version_insert_4.6.1">      
      <querytext>
      
		begin
		:1 := apm_package_version.new(
			version_id => :version_id,
			package_key => :package_key,
			version_name => :version_name,
			version_uri => :version_uri,
			summary => :summary,
			description_format => :description_format,
			description => :description,
			release_date => :release_date,
			vendor => :vendor,
			vendor_uri => :vendor_uri,
                        auto_mount => :auto_mount,
			installed_p => 't',
			data_model_loaded_p => 't'
	              );
		end;
	    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_delete.apm_package_delete">      
      <querytext>
      
	begin
	    apm_package_type.drop_type(
	        package_key => :package_key,
	        cascade_p => 't'
            );
	end;
    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_version_delete.apm_version_delete">      
      <querytext>
      
	begin
	 apm_package_version.del(version_id => :version_id);	 
	end;
    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_install_spec.version_mark_installed">      
      <querytext>
      
            update apm_package_versions
            set    installed_p = decode(version_id, :version_id, 't', 'f')
            where  package_key = :package_key
        
      </querytext>
</fullquery>


<fullquery name="apm_version_enable.apm_package_version_enable">      
      <querytext>
      
	begin
	  apm_package_version.enable(
            version_id => :version_id
	  );
	end;
    
      </querytext>
</fullquery>
 
<fullquery name="apm_version_disable.apm_package_version_disable">      
      <querytext>
      
	begin
	  apm_package_version.disable(
            version_id => :version_id
	  );
	end;
    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_register.application_register">      
      <querytext>
      
	    begin
	    apm.register_application (
		        package_key => :package_key,
			package_uri => :package_uri,
			pretty_name => :pretty_name,
			pretty_plural => :pretty_plural,
			initial_install_p => :initial_install_p,
			singleton_p => :singleton_p,
                        implements_subsite_p => :implements_subsite_p,
                        inherit_templates_p => :inherit_templates_p,
			spec_file_path => :spec_file_path,
			spec_file_mtime => :spec_file_mtime
          		);
	    end;					  
	
      </querytext>
</fullquery>

 
<fullquery name="apm_package_register.service_register">      
      <querytext>
      
	    begin
	    apm.register_service (
			package_key => :package_key,
			package_uri => :package_uri,
			pretty_name => :pretty_name,
			pretty_plural => :pretty_plural,
			initial_install_p => :initial_install_p,
			singleton_p => :singleton_p,
                        implements_subsite_p => :implements_subsite_p,
                        inherit_templates_p => :inherit_templates_p,
			spec_file_path => :spec_file_path,
			spec_file_mtime => :spec_file_mtime
			);
	    end;					  
	
      </querytext>
</fullquery>

 
<fullquery name="apm_version_update.apm_version_update">      
      <querytext>
      
	begin
	:1 := apm_package_version.edit(
				 version_id => :version_id, 
				 version_name => :version_name, 
				 version_uri => :version_uri,
				 summary => :summary,
				 description_format => :description_format,
				 description => :description,
				 release_date => :release_date,
				 vendor => :vendor,
				 vendor_uri => :vendor_uri,
                                 auto_mount => :auto_mount,
				 installed_p => 't',
				 data_model_loaded_p => 't'				 
				 );
	end;
    
      </querytext>
</fullquery>

<fullquery name="apm_version_upgrade.apm_version_upgrade">      
      <querytext>
      
	begin
	    apm_package_version.upgrade(version_id => :version_id);
	end;

    
      </querytext>
</fullquery>

 
<fullquery name="apm_upgrade_for_version_p.apm_upgrade_for_version_p">      
      <querytext>
      
	begin
	    :1 := apm_package_version.upgrade_p(
	              path => :path,
	              initial_version_name => :initial_version_name,
	              final_version_name => :final_version_name
	          );
	end;
    
      </querytext>
</fullquery>

 
<fullquery name="apm_upgrade_script_compare.test_f1">      
      <querytext>
      
	    begin
	    :1 := apm_package_version.sortable_version_name('$f1_version_from');
	    end;
	
      </querytext>
</fullquery>

 
<fullquery name="apm_upgrade_script_compare.test_f2">      
      <querytext>
      
	    begin
	    :1 := apm_package_version.sortable_version_name('$f2_version_from');
	    end;
	
      </querytext>
</fullquery>

<fullquery name="apm_dependency_provided_p.apm_dependency_check">      
      <querytext>
      
	select apm_package_version.version_name_greater(service_version, :dependency_version) as version_p
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
        select apm_package_version.version_name_greater(:provided_version, :dependency_version) from dual
      </querytext>
</fullquery>

<fullquery name="apm_copy_param_to_descendents.param_exists">      
  <querytext>
    begin
      :1 := apm.parameter_p(
               package_key => :descendent_package_key,
               parameter_name => :parameter_name);
    end;
  </querytext>
</fullquery>

<fullquery name="apm_copy_param_to_descendents.copy_descendent_param">      
  <querytext>
    begin
      :1 := apm.register_parameter(
               package_key => :descendent_package_key,
               parameter_name => :parameter_name,
               description => :description,
               scope => :scope,
               datatype => :datatype,
               default_value => :default_value,
               section_name => :section_name,
               min_n_values => :min_n_values,
               max_n_values => :max_n_values);
    end;
  </querytext>
</fullquery>

<fullquery name="apm_copy_inherited_params.param_exists">      
  <querytext>
    begin
      :1 := apm.parameter_p(
               package_key => :new_package_key,
               parameter_name => :parameter_name);
    end;
  </querytext>
</fullquery>

<fullquery name="apm_copy_inherited_params.copy_inherited_param">      
  <querytext>
    begin
      :1 := apm.register_parameter(
               package_key => :new_package_key,
               parameter_name => :parameter_name,
               description => :description,
               scope => :scope,
               datatype => :datatype,
               default_value => :default_value,
               section_name => :section_name,
               min_n_values => :min_n_values,
               max_n_values => :max_n_values);
    end;
  </querytext>
</fullquery>

<fullquery name="apm_package_upgrade_p.apm_package_upgrade_p">      
      <querytext>
      
	select apm_package_version.version_name_greater(:version_name, version_name) upgrade_p
	from apm_package_versions
	where package_key = :package_key
	and version_id = apm_package.highest_version (:package_key)
    
      </querytext>
</fullquery>

<fullquery name="apm_package_upgrade_from.apm_package_upgrade_from">      
      <querytext>
      
	    select version_name from apm_package_versions
	    where package_key = :package_key
	    and version_id = apm_package.highest_version(:package_key)
	
      </querytext>
</fullquery>

<fullquery name="apm_version_names_compare.select_sortable_versions">      
      <querytext>
      
	    select apm_package_version.sortable_version_name(:version_name_1) as sortable_version_1,
                   apm_package_version.sortable_version_name(:version_name_2) as sortable_version_2
            from   dual
	
      </querytext>
</fullquery>


<fullquery name="apm_version_sortable.sortable_version">
      <querytext>
	    select apm_package_version.sortable_version_name(:version) from dual
      </querytext>
</fullquery>

</queryset>
