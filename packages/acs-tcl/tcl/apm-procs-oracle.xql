<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="apm_highest_version.apm_highest_version">      
      <querytext>
      
	begin
	:1 := apm_package.highest_version (
                    package_key => :package_key
		    );
	end;
    
      </querytext>
</fullquery>

 
<fullquery name="apm_highest_version_name.apm_highest_version_name">      
      <querytext>
      
        select version_name 
        from   apm_package_versions
        where  package_key = :package_key
        and    version_id = apm_package.highest_version(:package_key)
    
      </querytext>
</fullquery>

 
<fullquery name="apm_parameter_register.parameter_register">      
      <querytext>
      
	    begin
	    :1 := apm.register_parameter(
					 parameter_id => :parameter_id,
					 package_key => :package_key,
					 parameter_name => :parameter_name,
					 description => :description,
                                         scope => :scope,
					 datatype => :datatype,
					 default_value => :default_value,
					 section_name => :section_name,
					 min_n_values => :min_n_values,
					 max_n_values => :max_n_values
	                                );
	    end;
	
      </querytext>
</fullquery>

<fullquery name="apm_parameter_unregister.unregister">
  <querytext>
    begin
      apm.unregister_parameter(:parameter_id);
    end;
  </querytext>
</fullquery>
 

<fullquery name="apm_dependency_add.dependency_add">      
      <querytext>
      
	begin
	:1 := apm_package_version.add_dependency(
            dependency_type => :dependency_type,
            dependency_id => :dependency_id,
	    version_id => :version_id,
	    dependency_uri => :dependency_uri,
	    dependency_version => :dependency_version
        );					 
	end;
    
      </querytext>
</fullquery>

 
<fullquery name="apm_dependency_remove.dependency_remove">      
      <querytext>
      
	begin
	apm_package_version.remove_dependency(
             dependency_id => :dependency_id
	);
	end;					        
    
      </querytext>
</fullquery>

 
<fullquery name="apm_interface_add.interface_add">      
      <querytext>
      
	begin
	:1 := apm_package_version.add_interface(
            interface_id => :interface_id,
	    version_id => :version_id,
	    interface_uri => :interface_uri,
	    interface_version => :interface_version
        );					 
	end;
    
      </querytext>
</fullquery>

 
<fullquery name="apm_interface_remove.interface_remove">      
      <querytext>
      
	begin
	apm_package_version.remove_interface(
             interface_id => :interface_id
	);
	end;					        
    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_instance_new.invoke_new">
      <querytext>
      
	begin
      :1 := apm_package.new(
        package_id => :package_id,
        instance_name => :instance_name,
        package_key => :package_key,
        context_id => :context_id
      );
	end;
    
      </querytext>
</fullquery>

<fullquery name="apm_package_instance_delete.apm_package_instance_delete">
  <querytext>
    begin
      apm_package.del(
	package_id => :package_id
      );
    end;
  </querytext>
</fullquery>

  <fullquery name="apm::convert_type.copy_new_params">
    <querytext>
      select apm_parameter_value.new(
               package_id => :package_id,
               parameter_id => ap.parameter_id,
               value => ap.default_value)
      from apm_parameters ap
      where ap.package_key = :new_package_key
        and not exists (select 1
                        from apm_parameters ap2
                        where ap2.package_key = :old_package_key
                          and ap2.parameter_name = ap.parameter_name)
    </querytext>
  </fullquery>
 
</queryset>
