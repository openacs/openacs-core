<?xml version="1.0"?>
<queryset>

<fullquery name="email_by_user_id">      
      <querytext>
      select email from parties where party_id = [ad_get_user_id]
      </querytext>
</fullquery>

 
<fullquery name="all_packages_owned_by_email">      
      <querytext>
      
    select v.package_key, v.version_id, v.package_name, v.version_name
    from   apm_package_version_info v, apm_package_owners o
    where  o.owner_url = :email
    and    v.version_id = o.version_id
    and    v.installed_p = 't'
    order by upper(package_name)
      </querytext>
</fullquery>

 
<fullquery name="apm_file_path">      
      <querytext>
      
	    select path from apm_package_files where version_id = :version_id
	
      </querytext>
</fullquery>

 
</queryset>
