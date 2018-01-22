<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="cr::keyword::new.content_keyword_new">
        <querytext>
            select content_keyword__new (
                :heading,    
                :description,
                :parent_id,  
                :keyword_id, 
                current_timestamp,
                :user_id,      
                :creation_ip,  
                :object_type,
                :package_id
            )
        </querytext>
    </fullquery>

    <fullquery name="cr::keyword::delete.delete_keyword">
        <querytext>
                select content_keyword__delete (:keyword_id)
        </querytext>
    </fullquery>

    <fullquery name="cr::keyword::set_heading.set_heading">
        <querytext>
            select content_keyword__set_heading(:keyword_id, :heading)
        </querytext>
    </fullquery>

    <fullquery name="cr::keyword::item_assign.keyword_assign">
        <querytext>
            select content_keyword__item_assign(
                :item_id,
                :keyword,
                null,
                null,
                null
            )
        </querytext>
    </fullquery>

   <fullquery name="content_symlink::new.symlink_new">      
      <querytext>

        select content_symlink__new (
          :name,
          :label,
          :target_id,
          :parent_id,
          :symlink_id,
          current_timestamp,
          :creation_user,
          :creation_ip,
          :package_id
        );

      </querytext>
   </fullquery>

   <fullquery name="content_symlink::delete.symlink_delete">      
      <querytext>

        select content_symlink__delete (
          :symlink_id
        );

      </querytext>
   </fullquery>

   <fullquery name="content_symlink::symlink_p.symlink_check">      
      <querytext>

        select content_symlink__is_symlink (
          :item_id
        );

      </querytext>
   </fullquery>

   <fullquery name="content_symlink::resolve.resolve_symlink">
      <querytext>
       
          select content_symlink__resolve (
	     :item_id
	  );
      </querytext>
   </fullquery>

  <fullquery name="content_symlink::resolve_content_type.resolve_content_type">
      <querytext>
       
          select content_symlink__resolve_content_type (
	     :item_id
	  );
      </querytext>
   </fullquery>



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


   <fullquery name="content_extlink::new.extlink_new">      
      <querytext>

        select content_extlink__new (
          :name,
          :url,
          :label,
          :description,
          :parent_id,
          :extlink_id,
          current_timestamp,
          :creation_user,
          :creation_ip,
          :package_id
        );

      </querytext>
   </fullquery>

   <fullquery name="content_extlink::delete.extlink_delete">      
      <querytext>

        select content_extlink__delete (
          :extlink_id
        );

      </querytext>
   </fullquery>

   <fullquery name="content_extlink::extlink_p.extlink_check">      
      <querytext>

        select content_extlink__is_extlink (
          :item_id
        );

      </querytext>
   </fullquery>

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


<fullquery name="folder::delete.delete_folder">
      <querytext>
        select content_folder__delete(:folder_id)
      </querytext>
</fullquery>


</queryset>
