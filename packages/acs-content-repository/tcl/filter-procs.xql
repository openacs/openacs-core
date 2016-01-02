<?xml version="1.0"?>
<queryset>

<fullquery name="content::get_content.get_revision">      
      <querytext>

        select live_revision from cr_items where item_id = :item_id

      </querytext>
</fullquery>

<fullquery name="content::get_content.get_mime_type">      
      <querytext>

        select mime_type from cr_revisions 
        where revision_id = :revision_id

      </querytext>
</fullquery>

<fullquery name="content::get_content.get_content_type">      
      <querytext>

        select content_type from cr_items 
        where item_id = :item_id

      </querytext>
</fullquery>

<fullquery name="content::get_content.get_table_name">      
      <querytext>

        select table_name from acs_object_types 
        where object_type = :content_type

      </querytext>
</fullquery>

<partialquery name="content::get_content.content_as_text">
	<querytext>

	, content as text

	</querytext>
</partialquery>

<fullquery name="content::get_content.get_content">      
      <querytext>

        select 
           x.*, 
          :content_type as content_type
          $text_sql
        from
          cr_revisions r, ${table_name}x x
        where
          r.revision_id = :revision_id
        and 
          x.revision_id = r.revision_id

      </querytext>
</fullquery>

</queryset>
