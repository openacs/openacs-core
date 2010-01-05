<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>
 
<fullquery name="apm_packages">      
      <querytext>
    select package_key, version_name,
        apm_package_version__sortable_version_name(version_name)
    from apm_package_versions
    where enabled_p
      and installed_p
      and package_key <> :package_key
    order by package_key, apm_package_version__sortable_version_name(version_name)
      </querytext>
</fullquery>

 
</queryset>
