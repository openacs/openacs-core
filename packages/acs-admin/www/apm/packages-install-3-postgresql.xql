<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="apm_package_upgrade_from">      
      <querytext>
      
	    select version_name from apm_package_versions
	    where package_key = :package_key
	    and version_id = apm_package__highest_version(:package_key)
	
      </querytext>
</fullquery>

 
</queryset>
