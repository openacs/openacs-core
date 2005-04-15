<?xml version="1.0"?>
<queryset>

<fullquery name="item::get_publish_status.gps_get_publish_status">      
      <querytext>
      
    select publish_status from cr_items where item_id = :item_id
  
      </querytext>
</fullquery>


<fullquery name="item::get_revision_content.grc_get_all_content">      
      <querytext>
      select 
    x.*, 
    :item_id as item_id $text_sql, 
    :content_type as content_type
  from
    cr_revisions r, ${table_name}x x
  where
    r.revision_id = :revision_id
  and 
    x.revision_id = r.revision_id
  
      </querytext>
</fullquery>

<fullquery name="item::content_methods_by_type.cmbt_get_content_mime_types">      
      <querytext>
      
    select mime_type from cr_content_mime_type_map
      where content_type = :content_type
      and lower(mime_type) like 'text/%'
  
      </querytext>
</fullquery>

<fullquery name="item::get_content_type.gct_get_content_type">      
      <querytext>
      
    select content_type from cr_items where
      item_id = :item_id
  
      </querytext>
</fullquery>
 
<fullquery name="item::get_item_from_revision.gifr_get_one_revision">      
      <querytext>
      
    select item_id from cr_revisions where revision_id = :revision_id
  
      </querytext>
</fullquery>

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

<fullquery name="item::unpublish.update_publish_status">
    <querytext>
        update cr_items
        set publish_status = :publish_status
        where item_id = :item_id
    </querytext>
</fullquery>

</queryset>
