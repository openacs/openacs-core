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
					 :datatype,
					 :default_value,
					 :section_name,
					 :min_n_values,
					 :max_n_values
	                                );
	
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

 
<fullquery name="apm_dependency_add.dependency_add">      
      <querytext>

	select apm_package_version__add_dependency(
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

 
<fullquery name="apm_package_version_installed_p.apm_package_version_installed_p">      
      <querytext>

	select case when count(*) = 0 then 0 else 1 end 
        from apm_package_versions
	where package_key = :package_key
	and version_name = :version_name
    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_instance_new.apm_package_instance_new">      
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

 
<fullquery name="apm_parameter_unregister.parameter_unregister">      
      <querytext>
      
	begin
	delete from apm_parameter_values 
	where parameter_id = :parameter_id;
	delete from apm_parameters 
	where parameter_id = :parameter_id;
	PERFORM acs_object__delete(:parameter_id);

        return null;
	end;
    
      </querytext>
</fullquery>

</queryset>
