<?xml version="1.0"?>
<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

  <fullquery name="lang::catalog::system_package_version_name.get_version_name">
    <querytext>
           select version_name
           from apm_package_version_info
           where version_id = apm_package.highest_version(:package_key)
    </querytext>
  </fullquery>

</queryset>
