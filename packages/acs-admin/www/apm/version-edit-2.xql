<?xml version="1.0"?>
<queryset>

<fullquery name="apm_version_uri_unique_ck">      
      <querytext>
	    select case when count(*) = 0 then 0 else 1 end from apm_package_versions 
	    where version_uri = :version_uri
	
      </querytext>
</fullquery>

 
<fullquery name="old_version_info">      
      <querytext>
      
	    select version_name as old_version_name, version_uri as old_version_uri 
	    from apm_package_versions
	    where version_id = $version_id
	
      </querytext>
</fullquery>

 
</queryset>
