<?xml version="1.0"?>
<queryset>

<fullquery name="apm_get_all_packages">      
      <querytext>
      
    select version_id, version_name, pretty_name, distribution_uri, v.package_key
    from   apm_package_versions v, apm_package_types t
    where  installed_p = 't'
    and v.package_key = t.package_key
    order by upper(pretty_name)

      </querytext>
</fullquery>

 
</queryset>
