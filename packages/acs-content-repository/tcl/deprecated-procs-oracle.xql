<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="cr::keyword::new.content_keyword_new">
        <querytext>
            begin
              :1 := content_keyword.new (
                :heading,    
                :description,
                :parent_id,  
                :keyword_id, 
                sysdate(),
                :user_id,      
                :creation_ip,  
                :object_type,
                :package_id
              );
            end;
        </querytext>
    </fullquery>

    <fullquery name="cr::keyword::delete.delete_keyword">
        <querytext>
            begin
                content_keyword.del(:keyword_id);
            end;
        </querytext>
    </fullquery>

    <fullquery name="cr::keyword::set_heading.set_heading">
        <querytext>
            begin
                content_keyword.set_heading(:keyword_id, :heading);
            end;
        </querytext>
    </fullquery>

    <fullquery name="cr::keyword::item_assign.keyword_assign">
        <querytext>
            begin
              content_keyword.item_assign(
                :item_id,
                :keyword,
                null,
                null,
                null
              );
            end;
        </querytext>
    </fullquery>
   <fullquery name="content_symlink::new.symlink_new">      
      <querytext>

        begin
          :1 := content_symlink.new (
                  name => :name,
                  target_id => :target_id,
                  label => :label,
                  parent_id => :parent_id,
                  symlink_id => :symlink_id,
                  creation_user => :creation_user,
                  creation_ip => :creation_ip,
                  package_id => :package_id
                );
        end;

      </querytext>
   </fullquery>

   <fullquery name="content_symlink::delete.symlink_delete">      
      <querytext>

          begin
            content_symlink.del (
              symlink_id => :symlink_id
            );
          end;

      </querytext>
   </fullquery>

   <fullquery name="content_symlink::symlink_p.symlink_check">      
      <querytext>

        select content_symlink.is_symlink (:item_id)
        from dual

      </querytext>
   </fullquery>

   <fullquery name="content_symlink::resolve.resolve_symlink">
      <querytext>
       
          select content_symlink.resolve (
	    :item_id
	  ) from dual

      </querytext>
   </fullquery>

  <fullquery name="content_symlink::resolve_content_type.resolve_content_type">
      <querytext>
       
          select content_symlink.resolve_content_type (
	    :item_id
	  ) from dual

      </querytext>
   </fullquery>

<partialquery name="item::get_revision_content.grc_get_all_content_1">
	<querytext>

	, content.blob_to_string(content) as text

	</querytext>
</partialquery>

<fullquery name="item::content_is_null.cin_get_content">      
      <querytext>
      
    select 't' from cr_revisions r, cr_items i
      where r.revision_id = :revision_id
        and i.item_id = r.item_id
        and ((r.content is not null and i.storage_type in ('lob','text')) or
             (r.filename is not null and i.storage_type = 'file'))
      </querytext>
</fullquery>

   <fullquery name="content_extlink::new.extlink_new">      
      <querytext>

        begin
          :1 := content_extlink.new (
                  name => :name,
                  url => :url,
                  label => :label,
                  description => :description,
                  parent_id => :parent_id,
                  extlink_id => :extlink_id,
                  creation_user => :creation_user,
                  creation_ip => :creation_ip,
                  package_id => :package_id
                );
        end;

      </querytext>
   </fullquery>

   <fullquery name="content_extlink::delete.extlink_delete">      
      <querytext>

          begin
            content_extlink.del (
              extlink_id => :extlink_id
            );
          end;

      </querytext>
   </fullquery>

   <fullquery name="content_extlink::extlink_p.extlink_check">      
      <querytext>

        select content_extlink.is_extlink (:item_id)
        from dual

      </querytext>
   </fullquery>

<fullquery name="content::get_folder_labels.get_url">      
      <querytext>

    select
      0 as tree_level, '' as name , 'Home' as title
    from
      dual
    UNION
    select
      t.tree_level, i.name, content_item.get_title(t.context_id) as title
    from (
      select 
        context_id, level as tree_level
      from 
        acs_objects
      where
        context_id <> content_item.get_root_folder
      connect by
        prior context_id = object_id
      start with
        object_id = :item_id
      ) t, cr_items i
    where
      i.item_id = t.context_id
    order by
      tree_level

      </querytext>
</fullquery>

 
<fullquery name="folder::delete.delete_folder">
      <querytext>
            begin
            content_folder.delete(:folder_id);
            end;
      </querytext>
</fullquery>


</queryset>
