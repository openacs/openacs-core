<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>
 
<fullquery name="item::get_title.gt_get_title">      
      <querytext>
      
    select content_item.get_title(:item_id) from dual
  
      </querytext>
</fullquery>

<fullquery name="item::is_publishable.ip_is_publishable_p">      
      <querytext>
      
    select content_item.is_publishable(:item_id) from dual
  
      </querytext>
</fullquery>

<partialquery name="item::get_revision_content.grc_get_all_content_1">
	<querytext>

	, content.blob_to_string(content) as text

	</querytext>
</partialquery>

<fullquery name="item::get_id.id_get_item_id">      
      <querytext>
      select content_item__get_id(:url $root_sql) from dual
  
      </querytext>
</fullquery>

<fullquery name="item::content_is_null.cin_get_content">      
      <querytext>
      
    select 't' from cr_revisions r, cr_items i
      where r.revision_id = :revision_id
        and i.item_id = r.item_id
        and ((r.content is not null and i.storage_type in ('lob','text')) or
             (r.filename is not null and i.storage_type = 'file'))
      </querytext>
</fullquery>

<fullquery name="item::get_template_id.gti_get_template_id">      
      <querytext>

    select content_item.get_template(:item_id, :context) as template_id
    from dual

      </querytext>
</fullquery>

<fullquery name="item::get_url.gu_get_path">      
      <querytext>
      
    select content_item.get_path(:item_id, $root_folder_id) from dual
  
      </querytext>
</fullquery>

<fullquery name="item::get_best_revision.gbr_get_best_revision">      
      <querytext>
      
    select content_item.get_best_revision(:item_id) from dual
  
      </querytext>
</fullquery>

<fullquery name="item::delete.delete_item">
      <querytext>
 
       begin
        content_item.delete(:item_id);
        end;
  
      </querytext>
</fullquery>

<fullquery name="item::copy.copy_item">      
      <querytext>
      
        begin
          content_item.copy(
            item_id => :item_id,
            target_folder_id => :target_folder_id,
            creation_user => :creation_user,
            creation_ip => :creation_ip
          );
        end; 
  
      </querytext>
</fullquery>

<fullquery name="item::publish.set_live">
    <querytext>
        begin
            content_item.set_live_revision(
                revision_id => :revision_id,
                publish_status => 'live'
            );
        end;
    </querytext>
</fullquery>

<fullquery name="item::unpublish.unset_live">
    <querytext>
        begin
            content_item.unset_live_revision(
                 item_id => :item_id
            );
        end;
    </querytext>
</fullquery>

</queryset>
