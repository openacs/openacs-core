<?xml version="1.0"?>
<queryset>

<fullquery name="apm_all_version_info">      
      <querytext>
      
    select version_id, package_key, package_uri, pretty_name, version_name,
      version_uri, auto_mount, summary, description_format, description, release_date,
      vendor, vendor_uri, enabled_p, installed_p, tagged_p, imported_p,
      data_model_loaded_p, activation_date, tarball_length, 
      deactivation_date, distribution_uri, distribution_date, singleton_p,
      initial_install_p, implements_subsite_p, inherit_templates_p
    from apm_package_version_info where version_id = :version_id

      </querytext>
</fullquery>

 
<fullquery name="apm_all_owners">      
      <querytext>
      
    select owner_name, owner_uri from apm_package_owners where version_id = :version_id

      </querytext>
</fullquery>

 
</queryset>
