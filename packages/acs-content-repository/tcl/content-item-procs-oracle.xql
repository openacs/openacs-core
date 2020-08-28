<?xml version="1.0"?>

<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

  <fullquery name="content::item::content_is_null.cin_get_content">
    <querytext>
      select 't' from cr_revisions r, cr_items i
      where r.revision_id = :revision_id
      and i.item_id = r.item_id
      and ((r.content is not null and i.storage_type in ('lob','text')) or
      (r.filename is not null and i.storage_type = 'file'))
    </querytext>
  </fullquery>
</queryset>
