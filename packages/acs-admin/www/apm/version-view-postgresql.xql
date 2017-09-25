<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="apm_enabled_version_info">      
      <querytext>
    select version_id   as installed_version_id,
           version_name as installed_version_name,
           enabled_p    as installed_enabled_p
    from   apm_package_versions
    where  package_key = :package_key
    and    installed_p = 't'
    limit 1
      </querytext>
</fullquery>

 
<fullquery name="apm_data_model_install_version">      
      <querytext>
    select data_model_installed_version from (
        select version_name as data_model_installed_version
        from   apm_package_versions
        where  package_key = :package_key
        and    data_model_loaded_p = 't'
        order by apm_package_version__sortable_version_name(version_name) desc
    ) as bad_postgres_needs_this
    limit 1

      </querytext>
</fullquery>

 
</queryset>
