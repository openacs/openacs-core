<?xml version="1.0"?>
<queryset>

  <fullquery name="cr_write_content.get_revision_info">
    <querytext>
      select i.storage_type, i.storage_area_key, r.mime_type, i.item_id,
      r.content_length
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

  <fullquery name="cr_import_content.get_content_type">
    <querytext>
      select content_type
      from cr_items
      where item_id = :item_id
    </querytext>
  </fullquery>

  <fullquery name="cr_import_content.mime_type_insert">
    <querytext>
      insert into cr_mime_types (mime_type) 
      select :mime_type
      from dual
      where not exists (select 1 from cr_mime_types where mime_type = :mime_type)
    </querytext>
  </fullquery>

  <fullquery name="cr_registered_type_for_mime_type.registered_type_for_mime_type">
    <querytext>
      select content_type
      from cr_content_mime_type_map
      where mime_type = :mime_type
    </querytext>
  </fullquery>

  <fullquery name="cr_import_content.is_registered">
    <querytext>
      select 1
      from cr_content_mime_type_map
      where mime_type = :mime_type
      and content_type = 'content_revision'
    </querytext>
  </fullquery>

  <fullquery name="cr_check_mime_type.lookup_mimetype">
    <querytext>
      select mime_type
        from cr_extension_mime_type_map
       where extension = :extension
    </querytext>
  </fullquery>

  <fullquery name="cr_filename_to_mime_type.lookup_mimetype">
    <querytext>
      select mime_type
        from cr_extension_mime_type_map
       where extension = :extension
    </querytext>
  </fullquery>

  <fullquery name="cr_import_content.image_type_p">
    <querytext>
      select 1
      from cr_content_mime_type_map
      where mime_type = :mime_type
      and content_type = 'image'
    </querytext>
  </fullquery>

</queryset>
