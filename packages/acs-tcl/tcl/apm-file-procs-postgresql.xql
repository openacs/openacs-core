<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="apm_generate_tarball.create_item">      
      <querytext>

select content_item__new(
         varchar :name,
         null,
         null,
         null,
         now(),
         null,
         null,
         :creation_ip,
         'content_item',
         'content_revision',
         null,
         null,
         'text/plain',
         null,
         null,
         'file'
         )

      </querytext>
</fullquery>

<fullquery name="apm_generate_tarball.create_revision">      
      <querytext>

  declare
        v_revision_id      integer;
  begin

  v_revision_id := content_revision__new(
                                       :title,
                                       'gzipped tarfile',
                                       now(),
                                       'text/plain',
                                       null,
                                       'not_important',
                                       :item_id,
                                       null,
                                       now(),
                                       :user_id,
                                       :creation_ip
                                       );

  update cr_items
  set live_revision = v_revision_id
  where item_id = :item_id;

  return v_revision_id;

  end;

      </querytext>
</fullquery>

<fullquery name="apm_generate_tarball.update_tarball">      
      <querytext>

    update cr_revisions
    set content = '[set content_file [cr_create_content_file $item_id $revision_id $tmpfile]]'
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

   select '[cr_fs_path]' || r.content as content, i.storage_type
     from cr_revisions r, cr_items i
    where r.item_id = i.item_id
      and r.revision_id = (select content_item__get_latest_revision(item_id)
                             from apm_package_versions 
                            where version_id = :version_id)

      </querytext>
</fullquery>
 
<fullquery name="apm_file_add.apm_file_add">      
      <querytext>

	select apm_package_version__add_file(
		:file_id,
		:version_id,
		:path,
		:file_type,
                :db_type
		)
    
      </querytext>
</fullquery>

 
<fullquery name="apm_file_remove.apm_file_remove">      
      <querytext>

	select apm_package_version__remove_file(
				:version_id,
				:path
				)
    
      </querytext>
</fullquery>

 
</queryset>
