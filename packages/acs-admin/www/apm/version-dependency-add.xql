<?xml version="1.0"?>
<queryset>

<fullquery name="apm_package_info_by_version_id_and_package">      
      <querytext>
      
    select p.package_key, p.package_uri, p.pretty_name, v.version_name
    from   apm_package_types p, apm_package_versions v
    where  v.version_id = :version_id
    and    v.package_key = p.package_key

      </querytext>
</fullquery>

</queryset>
