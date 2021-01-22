<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="apm_generate_tarball.update_tarball">      
      <querytext>

                update cr_revisions
                set filename = '[set content_file [cr_create_content_file $item_id $revision_id $tmpfile]]'
                where revision_id = :revision_id

      </querytext>
</fullquery>

<fullquery name="apm_generate_tarball.update_content_length">      
      <querytext>

                update apm_package_versions
                   set content_length = [cr_file_size $content_file]
                 where version_id = :version_id

      </querytext>
</fullquery>


<fullquery name="apm_extract_tarball.distribution_tar_ball_select">      
      <querytext>

   select  '[cr_fs_path]' || r.filename as content, i.storage_type
     from cr_revisions r, cr_items i
    where r.item_id = i.item_id
      and r.revision_id = (select content_item.get_latest_revision(item_id)
                           from apm_package_versions 
                          where version_id = :version_id)

      </querytext>
</fullquery>
 
</queryset>
