<?xml version="1.0"?>
<queryset>

<fullquery name="cr_revision_upload.get_revision_id">      
      <querytext>

        select content_revision__new(:title, 
                                     null,
                                     now(),
                                     'text/plain',
                                     ' ',
                                     :item_id
                                     )

      </querytext>
</fullquery>

<fullquery name="cr_revision_upload.dml_revision_from_file">      
      <querytext>

                         update 
                            cr_revisions 
                          set
                            content = '[cr_create_content_file $item_id $revision_id $path]'
                          where
                            revision_id = :revision_id

      </querytext>
</fullquery>

<fullquery name="cr_write_content.get_revision_info">
      <querytext>
          select i.storage_type, i.storage_area_key, r.mime_type, i.item_id
          from cr_items i, cr_revisions r
          where r.revision_id = :revision_id and i.item_id = r.item_id
      </querytext>
</fullquery>

<fullquery name="cr_write_content.write_text_content">
      <querytext>
          select content
          from cr_revisions
          where revision_id = :revision_id
      </querytext>
</fullquery>

</queryset>
