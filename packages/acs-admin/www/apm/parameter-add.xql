<?xml version="1.0"?>
<queryset>

<fullquery name="apm_get_name">      
      <querytext>
       
    select package_key, pretty_name, version_name
      from apm_package_version_info
     where version_id = :version_id

      </querytext>
</fullquery>

 
</queryset>
