<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="apm_package_install.package_instantiate_mount">      
      <querytext>

	        select apm_package__new(
                                  null,
	                          :package_name,
			  	  :package_key,
                                  'apm_package',
                                  now(),
                                  null,
                                  null,
				  acs__magic_object_id('default_context')
				  );
	    
      </querytext>
</fullquery>

 
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
			:singleton_p,
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
			:singleton_p,
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
				 't',
				 't'				 
				 );
    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_instantiate_and_mount.package_instantiate_mount">      
      <querytext>

	    declare
	            main_site_id  site_nodes.node_id%TYPE;
  	            instance_id   apm_packages.package_id%TYPE;
	            node_id       site_nodes.node_id%TYPE;
	    begin
	            main_site_id := site_node__node_id('/',null);
	        
	            instance_id := apm_package__new(
                                  null,
                                  null,
			  	  :package_key,
                                  'apm_package',
                                  now(),
                                  null,
                                  null,
				  main_site_id
				  );

		    node_id := site_node__new(
                             null
			     main_site_id,
			     :package_key,
			     instance_id,
			     't',
			     't',
                             null,
                             null
			  );

                    return null;
	    end;
	    
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

 
<fullquery name="apm_upgrade_script_compare.test">      
      <querytext>

	    select apm_package_version__sortable_version_name('$f1_version_from');
	
      </querytext>
</fullquery>

 
<fullquery name="apm_upgrade_script_compare.test">      
      <querytext>

	    select apm_package_version__sortable_version_name('$f1_version_from');
	
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

<fullquery name="apm_package_install.version_exists_p">      
      <querytext>
      
	    select version_id 
	    from apm_package_versions 
	    where package_key = :package_key
	    and version_id = apm_package__highest_version(:package_key)
	
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

</queryset>
