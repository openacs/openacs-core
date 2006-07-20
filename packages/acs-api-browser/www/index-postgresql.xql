<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_local_package_version_id">
      <querytext>

        select version_id
          from apm_package_version_info
        where installed_p = 't'
          and enabled_p = 't'
          and package_key = :about_package_key
	limit 1 
    
      </querytext>
</fullquery>

 
</queryset>
