<?xml version="1.0"?>
<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>
 
<fullquery name="apm_all_files">      
      <querytext>
    select ftd.file_id, ftd.path, ftd.file_type, coalesce(ftd.pretty_name, 'Unknown type') as file_pretty_name,
           ftd.db_type, coalesce(ftd.pretty_db_name, 'All') as db_pretty_name
    from   ((apm_package_files f left join apm_package_file_types t on (f.file_type = t.file_type_key))
            left join apm_package_db_types d on (f.db_type = d.db_type_key)) ftd
    where  ftd.version_id = :version_id
    order by ftd.path

      </querytext>
</fullquery>

</queryset>
