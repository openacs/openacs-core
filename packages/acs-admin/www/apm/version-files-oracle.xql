<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>
 
<fullquery name="apm_all_files">      
      <querytext>
           select f.file_id, f.path, f.file_type, nvl(t.pretty_name, 'Unknown type') file_pretty_name,
                  f.db_type, nvl(d.pretty_db_name, 'All') as db_pretty_name
           from   apm_package_files f, apm_package_file_types t, apm_package_db_types d
           where  f.version_id = :version_id
           and    f.file_type = t.file_type_key(+)
           and    f.db_type = d.db_type_key(+)
           order by path
      </querytext>
</fullquery>

</queryset>
