<?xml version="1.0"?>
<queryset>

  <fullquery name="installed_packages">
    <querytext>
      select package_key,
             pretty_name as pretty_name
      from   apm_package_types
      order  by upper(pretty_name), pretty_name
    </querytext>
  </fullquery>

  <fullquery name="global_params_exist">
    <querytext>
      select count(*) as global_params
      from apm_parameters
      where package_key = :package_key
        and scope = 'global'
    </querytext>
  </fullquery>

</queryset>
