<?xml version="1.0"?>
<queryset>

<fullquery name="apm_package_drop_scripts">      
      <querytext>
      
    select file_id, path 
    from apm_package_files
    where version_id = :version_id
    and file_type = 'data_model_drop'
    and (db_type is null or db_type = :db_type)

      </querytext>
</fullquery>

 
</queryset>
