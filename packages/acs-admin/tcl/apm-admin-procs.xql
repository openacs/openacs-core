<?xml version="1.0"?>
<queryset>

<fullquery name="apm_parameter_section_slider.apm_parameter_sections">      
      <querytext>
      
	select distinct(section_name) 
	from apm_parameters
	where package_key = :package_key
    
      </querytext>
</fullquery>

 
</queryset>
