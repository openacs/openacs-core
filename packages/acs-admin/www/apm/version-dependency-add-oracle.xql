<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>
<fullquery name="apm_all_service_uri">      
      <querytext>
    select distinct service_uri, service_version
    from   apm_package_dependencies
    order by service_uri, apm_package_version.sortable_version_name(service_version)

      </querytext>
</fullquery>

 
</queryset>
