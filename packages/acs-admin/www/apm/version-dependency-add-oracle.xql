<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>
<fullquery name="apm_packages">      
      <querytext>
    select package_key, version_name
    from   apm_package_versions
    where enabled_p = 't'
      and installed_p = 't'
      and package_key <> :package_key
    order by package_key, apm_package_version.sortable_version_name(version_name)
      </querytext>
</fullquery>

 
</queryset>
