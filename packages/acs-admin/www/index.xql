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

</queryset>
