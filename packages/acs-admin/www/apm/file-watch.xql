<?xml version="1.0"?>
<queryset>

<fullquery name="apm_get_file_to_watch">      
      <querytext>
      
    select t.package_key,  t.pretty_name, 
           v.version_name, v.package_key, v.installed_p, 
           f.path, f.version_id
    from   apm_package_types t, apm_package_versions v, apm_package_files f
    where  f.file_id = :file_id
    and    f.version_id = v.version_id
    and    v.package_key = t.package_key

      </querytext>
</fullquery>

 
<fullquery name="apm_get_path_from_file_id">      
      <querytext>
      
    select path from apm_package_files where file_id = :file_id

      </querytext>
</fullquery>

 
</queryset>
