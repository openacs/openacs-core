<?xml version="1.0"?>
<queryset>

<fullquery name="apm_pretty_plural_unique_ck">      
      <querytext>
	    select case when count(*) = 0 then 0 else 1 end from apm_package_types 
	    where pretty_plural = :pretty_plural
	
      </querytext>
</fullquery>

 
<fullquery name="apm_name_unique_ck">      
      <querytext>
	    select case when count(*) = 0 then 0 else 1 end from apm_package_types 
	    where pretty_name = :pretty_name
	
      </querytext>
</fullquery>

 
<fullquery name="apm_uri_unique_ck">      
      <querytext>
	    select case when count(*) = 0 then 0 else 1 end from apm_package_types 
	    where package_uri = :package_uri
	
      </querytext>
</fullquery>

 
<fullquery name="apm_version_uri_unique_ck">      
      <querytext>
	    select case when count(*) =  0 then 0 else 1 end from apm_package_versions 
	    where version_uri = :version_uri
	
      </querytext>
</fullquery>

 
<fullquery name="apm_package_add_doubleclick">      
      <querytext>
	select case when count(*) = 0 then 0 else 1 end from apm_package_versions
	where version_id = :version_id
    
      </querytext>
</fullquery>

 
</queryset>
