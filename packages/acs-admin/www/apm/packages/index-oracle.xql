<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="apm_archive_exist_p">      
      <querytext>

 select count(*) 
   from cr_revisions 
  where revision_id = (select content_item.get_latest_revision(item_id) 
                         from apm_package_versions
                  	where version_id = :version_id)

      </querytext>
</fullquery>

 
<fullquery name="apm_archive_serve">      
      <querytext>

 
 select '[cr_fs_path]' || filename as content, 
        '[set storage_type file]' as storage_type
   from cr_revisions 
  where revision_id = (select content_item.get_latest_revision(item_id) 
                         from apm_package_versions
                  	where version_id = $version_id)

      </querytext>
</fullquery>

 
</queryset>
