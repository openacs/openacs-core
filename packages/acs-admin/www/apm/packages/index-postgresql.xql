<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="apm_archive_exist_p">      
      <querytext>

 select count(*) 
   from cr_revisions 
  where revision_id = (select content_item__get_latest_revision(item_id) 
                         from apm_package_versions
                  	where version_id = :version_id)

      </querytext>
</fullquery>

 
<fullquery name="apm_archive_serve">      
      <querytext>

 select '[cr_fs_path]' || r.content as content, i.storage_type
   from cr_revisions r, cr_items i
  where r.item_id = i.item_id 
    and r.revision_id = (select content_item__get_latest_revision(item_id) 
                         from apm_package_versions
                  	where version_id = :version_id)

      </querytext>
</fullquery>

 
</queryset>
