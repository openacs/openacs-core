<?xml version="1.0"?>
<queryset>
  <rdbms><type>postgresql</type><version>7.2</version></rdbms>

  <fullquery name="lang::catalog::system_package_version_name.get_version_name">
    <querytext>
           select version_name
           from apm_package_version_info
           where version_id = apm_package__highest_version(:package_key)
    </querytext>
  </fullquery>

</queryset>
