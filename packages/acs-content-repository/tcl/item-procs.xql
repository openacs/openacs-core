<?xml version="1.0"?>
<queryset>

<fullquery name="item::get_type.get_content_type">
  <querytext>
    select content_type from cr_items
    where item_id = :item_id
  </querytext>
</fullquery>

<fullquery name="item::get_live_revision.glr_get_live_revision">      
      <querytext>
      
    select live_revision from cr_items
      where item_id = :item_id

      </querytext>
</fullquery>

<fullquery name="item::get_mime_info.gmi_get_mime_info">      
      <querytext>
      
    select 
      m.mime_type, m.file_extension
    from
      cr_mime_types m, cr_revisions r
    where
      r.mime_type = m.mime_type
    and
      r.revision_id = $revision_id
  
      </querytext>
</fullquery>

</queryset>
