<?xml version="1.0"?>
<queryset>

<fullquery name="apm_file_add_doubleclick_ck">      
      <querytext>
      
	    select count(*) from apm_package_files
	    where version_id = :version_id
	    and path = :index_path
	
      </querytext>
</fullquery>

 
</queryset>
