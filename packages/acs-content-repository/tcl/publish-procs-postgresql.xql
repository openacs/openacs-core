<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="publish::handle::text.get_revision_id">      
      <querytext>

        select 1

      </querytext>
</fullquery>

<fullquery name="publish::handle::text.get_previous_content">      
      <querytext>

                       select 
                         content
                       from 
                         cr_revisions
                       where 
                         revision_id = :revision_id

      </querytext>
</fullquery>

<fullquery name="publish::write_multiple_blobs.wmb_get_blob_file">      
      <querytext>

      select case when i.storage_type = 'file' 
                       then '[cr_fs_path]' || r.content
                  when i.storage_type = 'lob'
                       then lob::text 
                       else r.content end as content, i.storage_type 
      from cr_revisions r, cr_items i 
      where r.item_id = i.item_id and r.revision_id = $revision_id

      </querytext>
</fullquery>

<fullquery name="publish::write_content.get_previous_content">      
      <querytext>
      
    select 
      content
    from 
      cr_revisions
    where 
      revision_id = :revision_id
  
      </querytext>
</fullquery>
 
</queryset>
