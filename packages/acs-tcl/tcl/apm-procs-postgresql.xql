<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="apm_highest_version.apm_highest_version">      
      <querytext>

	select  apm_package__highest_version (
                    :package_key
		    );
    
      </querytext>
</fullquery>

 
<fullquery name="apm_highest_version_name.apm_highest_version_name">      
      <querytext>
      
        select version_name 
        from   apm_package_versions
        where  package_key = :package_key
        and    version_id = apm_package__highest_version(:package_key)
    
      </querytext>
</fullquery>


<fullquery name="apm_num_instances.apm_num_instances">      
      <querytext>

	select apm_package__num_instances(
		:package_key
		);
    
      </querytext>
</fullquery>

 
<fullquery name="apm_parameter_register.parameter_register">      
      <querytext>

	    select apm__register_parameter(
					 :parameter_id,
					 :package_key,
					 :parameter_name,
					 :description,
                                         :scope,
					 :datatype,
					 :default_value,
					 :section_name,
					 :min_n_values,
					 :max_n_values
	                                );
	
      </querytext>
</fullquery>

<fullquery name="apm_parameter_unregister.unregister">
  <querytext>
    select apm__unregister_parameter(:parameter_id)
  </querytext>
</fullquery>

<fullquery name="apm_dependency_add.dependency_add">      
      <querytext>

	select apm_package_version__add_dependency(
            :dependency_type,
            :dependency_id,
	    :version_id,
	    :dependency_uri,
	    :dependency_version
        );					 
    
      </querytext>
</fullquery>

 
<fullquery name="apm_dependency_remove.dependency_remove">      
      <querytext>

	select apm_package_version__remove_dependency(
             :dependency_id
	);
    
      </querytext>
</fullquery>

 
<fullquery name="apm_interface_add.interface_add">      
      <querytext>

	select apm_package_version__add_interface(
            :interface_id,
	    :version_id,
	    :interface_uri,
	    :interface_version
        );					 
    
      </querytext>
</fullquery>

 
<fullquery name="apm_interface_remove.interface_remove">      
      <querytext>

	select apm_package_version__remove_interface(
             :interface_id
	);
    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_version_installed_p.apm_package_version_installed_p">      
      <querytext>

	select case when count(*) = 0 then 0 else 1 end 
        from apm_package_versions
	where package_key = :package_key
	and version_name = :version_name
    
      </querytext>
</fullquery>

<fullquery name="apm_package_instance_new.invoke_new">
      <querytext>

      select apm_package__new(
        :package_id,
        :instance_name,
        :package_key,
        'apm_package',
        now(),
        null,
        null,
        :context_id
      );
    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_instance_delete.apm_package_instance_delete">
  <querytext>
	select apm_package__delete(:package_id);
  </querytext>
</fullquery>

<fullquery name="apm_package_url_from_id_mem.apm_package_url_from_id">      
      <querytext>
      
	select site_node__url(min(node_id))
          from site_nodes 
         where object_id = :package_id
    
      </querytext>
</fullquery>

<fullquery name="apm_application_new_checkbox.package_types">
      <querytext>
         select package_key,
         pretty_name
         from apm_package_types
         where not (apm_package__singleton_p(package_key) = 1 and
                    apm_package__num_instances(package_key) >= 1)
         order by pretty_name
      </querytext>
</fullquery>

  <fullquery name="apm::convert_type.copy_new_params">
    <querytext>
      select apm_parameter_value__new(null, :package_id, ap.parameter_id, ap.default_value)
      from apm_parameters ap
      where ap.package_key = :new_package_key
        and not exists (select 1
                        from apm_parameters ap2
                        where ap2.package_key = :old_package_key
                          and ap2.parameter_name = ap.parameter_name)
    </querytext>
  </fullquery>

</queryset>
