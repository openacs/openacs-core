<?xml version="1.0"?>
<queryset>

<fullquery name="apm_file_type_keys.file_type_keys">      
      <querytext>
      select file_type_key from apm_package_file_types
      </querytext>
</fullquery>

 
<fullquery name="apm_db_type_keys.db_type_keys">      
      <querytext>
      select db_type_key from apm_package_db_types
      </querytext>
</fullquery>

 
<fullquery name="apm_generate_tarball.package_key_select">      
      <querytext>
      select package_key from apm_package_version_info where version_id = :version_id
      </querytext>
</fullquery>

 
<fullquery name="apm_version_from_file.apm_version_id_from_file">      
      <querytext>
      
	select version_id from apm_package_files
	where file_id = :file_id
    
      </querytext>
</fullquery>

 
<fullquery name="apm_filelist_update.package_key_for_version_id">      
      <querytext>
      
	select package_key from apm_package_versions 
	where version_id = :version_id
    
      </querytext>
</fullquery>

 
<fullquery name="apm_filelist_update.apm_all_files">      
      <querytext>
      
	select f.file_id, f.path
	from   apm_package_files f
	where  f.version_id = :version_id
	order by path
    
      </querytext>
</fullquery>

 
<fullquery name="apm_version_file_list.path_select">      
      <querytext>
      
        select path from apm_package_files
        where  version_id = :version_id
        $type_sql $db_type_sql order by path
    
      </querytext>
</fullquery>

 
</queryset>
