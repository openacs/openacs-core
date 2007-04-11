<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="item::get_title.gt_get_title">      
      <querytext>
      
    select content_item__get_title(:item_id, 'f') 
  
      </querytext>
</fullquery>

<fullquery name="item::is_publishable.ip_is_publishable_p">      
      <querytext>
      
    select content_item__is_publishable(:item_id) 
  
      </querytext>
</fullquery>

<partialquery name="item::get_revision_content.grc_get_all_content_1">
	<querytext>

	, content as text

	</querytext>
</partialquery>

<fullquery name="item::get_id.id_get_item_id">      
      <querytext>

      select content_item__get_id(:url $root_sql) 
  
      </querytext>
</fullquery>

<fullquery name="item::content_is_null.cin_get_content">      
      <querytext>
      
    select 't' from cr_revisions r, cr_items i
      where r.revision_id = :revision_id
        and i.item_id = r.item_id
        and ((r.content is not null and i.storage_type in ('text','file')) or
             (r.lob is not null and i.storage_type = 'lob'))

      </querytext>
</fullquery>

<fullquery name="item::get_template_id.gti_get_template_id">      
      <querytext>

    select content_item__get_template(:item_id, :context) as template_id
    from dual

      </querytext>
</fullquery>

<fullquery name="item::get_url.gu_get_path">      
      <querytext>
      
    select content_item__get_path(:item_id, $root_folder_id) 
  
      </querytext>
</fullquery>

<fullquery name="item::get_best_revision.gbr_get_best_revision">      
      <querytext>
      
    select content_item__get_best_revision(:item_id) 
  
      </querytext>
</fullquery>

<fullquery name="item::copy.copy_item">      
      <querytext>
      
         select content_item__copy(
                  :item_id,
                  :target_folder_id,
                  :creation_user,
                  :creation_ip
                )
  
      </querytext>
</fullquery>

<fullquery name="item::publish.set_live">
    <querytext>
      select content_item__set_live_revision(
          :revision_id,
          'live'
      )
    </querytext>
</fullquery>

<fullquery name="item::unpublish.unset_live">
    <querytext>
            select content_item__unset_live_revision(
                 :item_id
            );
    </querytext>
</fullquery>
      
</queryset>
