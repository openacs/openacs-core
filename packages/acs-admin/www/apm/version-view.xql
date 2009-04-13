<?xml version="1.0"?>
<queryset>

<fullquery name="apm_all_version_info">      
      <querytext>
      
    select version_id, package_key, package_uri, pretty_name, version_name, version_uri,
    summary, description_format, description, singleton_p, initial_install_p,
    implements_subsite_p, inherit_templates_p,
    to_char(release_date, 'Month DD, YYYY') as release_date , vendor, vendor_uri, auto_mount,
    enabled_p, installed_p, tagged_p, imported_p, data_model_loaded_p, 
    to_char(activation_date, 'Month DD, YYYY') as activation_date,
    tarball_length, distribution_uri,
    to_char(deactivation_date, 'Month DD, YYYY') as deactivation_date,
    to_char(distribution_date, 'Month DD, YYYY') as distribution_date
 from apm_package_version_info 
 where version_id = :version_id

      </querytext>
</fullquery>

 
<fullquery name="supported_databases">      
      <querytext>
      
    select pretty_db_name
    from apm_package_db_types
    where exists (select 1
                  from apm_package_files
                  where version_id = :version_id
                  and   db_type = db_type_key)

      </querytext>
</fullquery>

 
<fullquery name="apm_all_owners">      
      <querytext>
      
    select owner_uri, owner_name from apm_package_owners where version_id = :version_id

      </querytext>
</fullquery>

 
</queryset>
