<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="cr_revision_upload.get_revision_id">      
      <querytext>

        begin
                :1 := content_revision.new(title     => :title, 
                                           item_id   => :item_id, 
                                           v_content => null);
        end;

      </querytext>
</fullquery>

<fullquery name="cr_revision_upload.dml_revision_from_file">      
      <querytext>

                         update 
                            cr_revisions 
                          set
                            content = empty_blob()
                          where
                            revision_id = :revision_id
                          returning content into :1

      </querytext>
</fullquery>

<fullquery name="cr_write_content.get_item_info">
      <querytext>
          select r.mime_type, i.storage_type, i.storage_area_key, r.revision_id
            from cr_revisions r, cr_items i
          where i.item_id = r.item_id and
              r.revision_id = content_item.get_live_revision(:item_id)
      </querytext>
</fullquery>

<fullquery name="cr_write_content.write_file_content">
      <querytext>
          select :path || filename
          from cr_revisions
          where revision_id = :revision_id
      </querytext>
</fullquery>

<fullquery name="cr_write_content.write_lob_content">
      <querytext>
          select content
          from cr_revisions
          where revision_id = $revision_id
      </querytext>
</fullquery>

</queryset>
