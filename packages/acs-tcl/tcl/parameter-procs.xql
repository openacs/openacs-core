<?xml version="1.0"?>
<queryset>
  <fullquery name="parameter::set_default.set">
    <querytext>
      update apm_parameters set default_value = :value where package_key = :package_key and parameter_name = :parameter
    </querytext>
  </fullquery>
</queryset>
