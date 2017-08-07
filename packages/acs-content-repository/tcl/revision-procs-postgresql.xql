<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="cr_write_content.get_item_info">
      <querytext>
          select i.storage_type, i.storage_area_key, r.mime_type,
          r.revision_id, r.content_length
          from cr_items i, cr_revisions r
          where r.revision_id = content_item__get_live_revision(:item_id) and i.item_id = r.item_id
      </querytext>
</fullquery>

<fullquery name="cr_write_content.write_file_content">
      <querytext>
          select :path || content
          from cr_revisions
          where revision_id = :revision_id
      </querytext>
</fullquery>

<fullquery name="cr_write_content.write_lob_content">
      <querytext>
          select lob as content, 'lob' as storage_type
          from cr_revisions
          where revision_id = :revision_id
      </querytext>
</fullquery>

<fullquery name="cr_import_content.mime_type_register">
      <querytext>
          select content_type__register_mime_type('content_revision', :mime_type)
      </querytext>
</fullquery>

<fullquery name="cr_import_content.image_subclass">
      <querytext>
         select content_item__is_subclass(:image_type, 'image')
      </querytext>
</fullquery>

<fullquery name="cr_import_content.content_revision_subclass">
      <querytext>
         select content_item__is_subclass(:other_type, 'content_revision')
      </querytext>
</fullquery>

<fullquery name="cr_import_content.image_new">
      <querytext>
         select image__new(
            /* name          => */ :object_name,
            /* parent_id     => */ :parent_id,
            /* item_id       => */ :item_id,
            /* revision_id   => */ :revision_id,
            /* mime_type     => */ :mime_type,
            /* creation_user => */ :creation_user,
            /* creation_ip   => */ :creation_ip,
            /* title         => */ :title,
            /* description   => */ :description,
            /* storage_type  => */ :storage_type,
            /* content_type  => */ :image_type,
            /* nls_language  => */ null,
            /* publish_date  => */ current_timestamp,
            /* height        => */ :original_height,
            /* width         => */ :original_width,
            /* package_id    => */ :package_id
         );
      </querytext>
</fullquery>

<fullquery name="cr_import_content.image_revision_new">
      <querytext>
         select image__new_revision (
            /* item_id       => */ :item_id,
            /* revision_id   => */ :revision_id,
            /* title         => */ :title,
            /* description   => */ :description,
            /* publish_date  => */ current_timestamp,
            /* mime_type     => */ :mime_type,
            /* nls_language  => */ null,
            /* creation_user => */ :creation_user,
            /* creation_ip   => */ :creation_ip,
            /* height        => */ :original_height,
            /* width         => */ :original_width,
            /* package_id    => */ :package_id
    );
      </querytext>
</fullquery>

<fullquery name="cr_import_content.content_item_new">
      <querytext>
         select content_item__new (
            /* name          => */ varchar :object_name,
            /* parent_id     => */ :parent_id,
            /* item_id       => */ :item_id,
            /* new_locale    => */ null,
            /* creation_date => */ current_timestamp,
            /* creation_user => */ :creation_user,
            /* context_id    => */ :parent_id,
            /* creation_ip   => */ :creation_ip,
            /* item_subtype  => */ 'content_item',
            /* content_type  => */ :other_type,
            /* title         => */ null,
            /* description   => */ null,
            /* mime_type     => */ null,
            /* nls_language  => */ null,
            /* text          => */ null,
            /* data          => */ null,
            /* relation_tag  => */ null,
            /* is live       => */ 'f',
            /* storage_type  => */ :storage_type,
            /* package_id    => */ :package_id,
            /* w_child_rels  => */ 't'
    );
      </querytext>
</fullquery>

<fullquery name="cr_import_content.content_revision_new">
      <querytext>
         select content_revision__new (
            /* title          => */ :title,
            /* description    => */ :description,
            /* publish_date   => */ current_timestamp,
            /* mime_type      => */ :mime_type,
            /* nls_language   => */ null,
            /* data           => */ null,
            /* item_id        => */ :item_id,
            /* revision_id    => */ :revision_id,
            /* creation_date  => */ current_timestamp,
            /* creation_user  => */ :creation_user,
            /* creation_ip    => */ :creation_ip,
	    /* content_length => */ null, 
            /* package_id     => */ :package_id
    );
      </querytext>
</fullquery>
 
<fullquery name="cr_import_content.set_lob_content">      
      <querytext>

	update cr_revisions
	set mime_type = :mime_type,
 	   lob = [set __lob_id [db_string get_lob_id {select empty_lob()}]]
	where revision_id = :revision_id
	   
      </querytext>
</fullquery>
 
<fullquery name="cr_import_content.set_lob_size">      
      <querytext>

         update cr_revisions
         set content_length = lob_length(lob)
         where revision_id = :revision_id

      </querytext>
</fullquery>

<fullquery name="cr_set_imported_content_live.set_live">
      <querytext>
          select content_item__set_live_revision(:revision_id)
      </querytext>
</fullquery>

<fullquery name="cr_import_content.set_file_content">
      <querytext>
          update cr_revisions
          set content = :filename,
              mime_type = :mime_type,
              content_length = :tmp_size
          where revision_id = :revision_id
      </querytext>
</fullquery>

</queryset>
