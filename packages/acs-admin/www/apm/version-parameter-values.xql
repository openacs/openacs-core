<?xml version="1.0"?>
<queryset>

<fullquery name="apm_package_by_version_id">      
      <querytext>
      
    select package_name, version_name, package_id from apm_package_version_info where version_id = :version_id

      </querytext>
</fullquery>

 
<fullquery name="apm_all_elements">      
      <querytext>
      
select element_id, element_name, description
from   ad_parameter_elements
where  version_id = :version_id
order by element_name

      </querytext>
</fullquery>

 
<fullquery name="apm_value">      
      <querytext>
      
	select value from ad_parameter_values where element_id = :element_id
    
      </querytext>
</fullquery>

 
</queryset>
