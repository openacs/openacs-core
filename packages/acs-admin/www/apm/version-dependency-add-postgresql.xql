<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>
 
<fullquery name="apm_all_service_uri">      
      <querytext>
    select distinct service_uri, service_version,
        apm_package_version__sortable_version_name(service_version)
    from apm_package_dependencies
    order by service_uri, apm_package_version__sortable_version_name(service_version)

      </querytext>
</fullquery>

 
</queryset>
