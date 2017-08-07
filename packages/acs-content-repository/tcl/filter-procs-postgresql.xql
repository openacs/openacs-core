<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="content::get_folder_labels.get_url">      
      <querytext>

      With RECURSIVE child_items AS (
        select 0 as lvl, i.item_id, ''::text as name, i.parent_id, 'Home'::text as title
	from cr_items i, cr_revisions r
	where i.item_id = :item_id and i.live_revision = r.revision_id
      UNION ALL
        select child_items.lvl+1, i.item_id, i.name, i.parent_id, r.title
	from cr_items i, cr_revisions r, child_items
        where i.parent_id = child_items.item_id and i.live_revision = r.revision_id
      )
      select * from child_items;    

      </querytext>
</fullquery>

<fullquery name="content::get_content_value.gcv_get_revision_id">
	<querytext>

        select 1

	</querytext>
</fullquery>

<fullquery name="content::get_content_value.gcv_get_previous_content">      
      <querytext>
      
    select 
      content
    from 
      cr_revisions
    where 
      revision_id = :revision_id
  
      </querytext>
</fullquery>

<fullquery name="content::init.get_template_url">      
      <querytext>

        select 
          content_item__get_live_revision(content_item__get_template(:item_id, :context)) as template_id,
          content_template__get_path(content_item__get_template(:item_id, :context),:template_root) as template_url 
        from dual

      </querytext>
</fullquery>

</queryset>
