<?xml version="1.0"?>
<queryset>

<fullquery name="param_info">      
      <querytext>
       
    select parameter_name, datatype, description, default_value, min_n_values, max_n_values, parameter_id, 
    section_name, default_value
      from apm_parameters
     where parameter_id = :parameter_id

      </querytext>
</fullquery>

 
<fullquery name="apm_get_name">      
      <querytext>
       
    select pretty_name, version_name, package_key
      from apm_package_version_info
     where version_id = :version_id

      </querytext>
</fullquery>

 
</queryset>
