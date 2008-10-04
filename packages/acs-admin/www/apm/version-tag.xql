<?xml version="1.0"?>
<queryset>

  <fullquery name="apm_package_by_version_id">
    <querytext>
      select pretty_name, version_name
      from apm_package_version_info 
      where version_id = :version_id
    </querytext>
  </fullquery>


<fullquery name="apm_all_paths">      
      <querytext>
      
	select path from apm_package_files where version_id = :version_id order by path

      </querytext>
</fullquery>

 
<fullquery name="apm_all_files_untag">      
      <querytext>
      
	update apm_package_versions 
	set    tagged_p   = 'f' 
	where  version_id = :version_id
    
      </querytext>
</fullquery>

 
<fullquery name="apm_all_files_tag">      
      <querytext>
      
	update apm_package_versions 
	set    tagged_p   = 't' 
	where  version_id = :version_id
    
      </querytext>
</fullquery>

 
</queryset>
