<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="cr_write_content.get_item_info">
      <querytext>
          select r.mime_type, i.storage_type, i.storage_area_key,
            r.revision_id, r.content_length
            from cr_revisions r, cr_items i
          where i.item_id = r.item_id and
              r.revision_id = content_item.get_live_revision(:item_id)
      </querytext>
</fullquery>

<fullquery name="cr_write_content.write_file_content">
      <querytext>
          select :path || filename
          from cr_revisions
          where revision_id = :revision_id
      </querytext>
</fullquery>

<fullquery name="cr_write_content.write_lob_content">
      <querytext>
          select content
          from cr_revisions
          where revision_id = $revision_id
      </querytext>
</fullquery>


<fullquery name="cr_import_content.mime_type_register">
      <querytext>
          begin
            content_type.register_mime_type('content_revision', :mime_type);
          end;
      </querytext>
</fullquery>

<fullquery name="cr_import_content.image_subclass">
      <querytext>
         select content_item.is_subclass(:image_type, 'image') from dual
      </querytext>
</fullquery>

<fullquery name="cr_import_content.content_revision_subclass">
      <querytext>
         select content_item.is_subclass(:other_type, 'content_revision') from dual
      </querytext>
</fullquery>

<fullquery name="cr_import_content.image_new">
      <querytext>
          begin
            :1 := image.new(
               name          =>  :object_name,
               parent_id     =>  :parent_id,
               item_id       =>  :item_id,
               revision_id   =>  :revision_id,
               mime_type     =>  :mime_type,
               creation_user =>  :creation_user,
               creation_ip   =>  :creation_ip,
               title         =>  :title,
               content_type  =>  :image_type,
               storage_type  =>  :storage_type,
               height        =>  :original_height,
               width         =>  :original_width,
               package_id    =>  :package_id
            );
          end;
      </querytext>
</fullquery>

<fullquery name="cr_import_content.image_revision_new">
      <querytext>
         begin
           :1 := image.new_revision (
             item_id       => :item_id,
             revision_id   => :revision_id,
             title         => :title,
             description   => :description,
             mime_type     => :mime_type,
             creation_user => :creation_user,
             creation_ip   => :creation_ip,
             height        => :original_height,
             width         => :original_width,
             package_id    => :package_id
           );
         end;
      </querytext>
</fullquery>

<fullquery name="cr_import_content.content_item_new">
      <querytext>
          begin
            :1 := content_item.new(
               name          =>  :object_name,
               item_id       =>  :item_id,
               parent_id     =>  :parent_id,
               context_id    =>  :parent_id,
               creation_user =>  :creation_user,
               creation_ip   =>  :creation_ip,
               content_type  =>  :other_type,
               storage_type  =>  :storage_type,
               package_id    =>  :package_id
            );
          end;
      </querytext>
</fullquery>

<fullquery name="cr_import_content.content_revision_new">
      <querytext>
         begin
           :1 := content_revision.new (
             title         => :title,
             description   => :description,
             mime_type     => :mime_type,
             item_id       => :item_id,
             revision_id   => :revision_id,
             creation_user => :creation_user,
             creation_ip   => :creation_ip,
             package_id    => :package_id,
	     filename      => :object_name
           );
         end;
      </querytext>
</fullquery>

<fullquery name="cr_import_content.set_lob_content">      
      <querytext>
      
        update cr_revisions
        set mime_type = :mime_type,
        content = empty_blob()
        where revision_id = :revision_id
        returning content into :1
	   
      </querytext>
</fullquery>

<fullquery name="cr_import_content.set_lob_size">      
      <querytext>

         update cr_revisions
         set content_length = dbms_lob.getlength(content)
         where revision_id = :revision_id

      </querytext>
</fullquery>

<fullquery name="cr_set_imported_content_live.set_live">
      <querytext>
         begin content_item.set_live_revision (revision_id => :revision_id);
         end;
      </querytext>
</fullquery>
 
<fullquery name="cr_import_content.set_file_content">
      <querytext>
          update cr_revisions
          set filename = :filename,
              mime_type = :mime_type,
              content_length = :tmp_size
          where revision_id = :revision_id
      </querytext>
</fullquery>

</queryset>
