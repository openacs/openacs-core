<?xml version="1.0"?>
<queryset>

<fullquery name="drop_file_query">      
      <querytext>
      
	select path from apm_package_files
	where file_id in ([join $sql_drop_scripts \",\"])
        and file_type='data_model_drop'
    
      </querytext>
</fullquery>

 
</queryset>
