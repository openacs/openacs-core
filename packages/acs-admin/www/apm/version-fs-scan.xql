<?xml version="1.0"?>
<queryset>

<fullquery name="apm_package_info">      
      <querytext>
      
    select p.package_key, p.package_url, v.package_name, v.version_name, v.package_id
    from   apm_packages p, apm_package_versions v
    where  v.version_id = :version_id
    and    v.package_id = p.package_id

      </querytext>
</fullquery>

 
</queryset>
