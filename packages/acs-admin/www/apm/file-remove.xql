<?xml version="1.0"?>
<queryset>

<fullquery name="apm_get_version_id">      
      <querytext>
      
select distinct version_id 
from apm_package_files 
where file_id in ([join $file_id ","])
      </querytext>
</fullquery>

 
<fullquery name="apm_delete_files">      
      <querytext>
      delete from apm_package_files 
    where file_id in ([join $file_id ","])
      </querytext>
</fullquery>

 
</queryset>
