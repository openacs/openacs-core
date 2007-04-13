<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<partialquery name="item::get_revision_content.grc_get_all_content_1">
	<querytext>

	, content as text

	</querytext>
</partialquery>

<fullquery name="item::content_is_null.cin_get_content">      
      <querytext>
      
    select 't' from cr_revisions r, cr_items i
      where r.revision_id = :revision_id
        and i.item_id = r.item_id
        and ((r.content is not null and i.storage_type in ('text','file')) or
             (r.lob is not null and i.storage_type = 'lob'))

      </querytext>
</fullquery>

</queryset>
