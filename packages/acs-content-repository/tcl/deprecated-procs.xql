<?xml version="1.0"?>
<queryset>

   <fullquery name="content_symlink::edit.symlink_update_object">      
      <querytext>

        update acs_objects
        set last_modified = current_timestamp,
          modifying_user = :modifying_user,
          modifying_ip = :modifying_ip,
          title = :label
        where object_id = :symlink_id

      </querytext>
   </fullquery>  
  
   <fullquery name="content_symlink::edit.symlink_update_symlink">      
      <querytext>

        update cr_symlinks
        set target_id = :target_id,
          label = :label,
          description = :description
        where symlink_id = :symlink_id

      </querytext>
   </fullquery>

   <fullquery name="content_symlink::symlink_name.symlink_name">      
      <querytext>
          select label
          from cr_symlinks
          where symlink_id = :item_id
      </querytext>
   </fullquery>



<fullquery name="item::get_revision_content.grc_get_table_names">      
      <querytext>
      
    select table_name from acs_object_types 
    where object_type = :content_type
  
      </querytext>
</fullquery>

<fullquery name="item::get_revision_content.grc_get_all_content">      
      <querytext>
      select 
    x.*, 
    :item_id as item_id $text_sql, 
    :content_type as content_type
  from
    cr_revisions r, ${table_name}x x
  where
    r.revision_id = :revision_id
  and 
    x.revision_id = r.revision_id
  
      </querytext>
</fullquery>

<fullquery name="item::content_methods_by_type.cmbt_get_content_mime_types">      
      <querytext>
      
    select mime_type from cr_content_mime_type_map
      where content_type = :content_type
      and lower(mime_type) like 'text/%'
  
      </querytext>
</fullquery>

<fullquery name="item::get_mime_info.gmi_get_mime_info">      
      <querytext>
      
    select 
      m.mime_type, m.file_extension
    from
      cr_mime_types m, cr_revisions r
    where
      r.mime_type = m.mime_type
    and
      r.revision_id = $revision_id
  
      </querytext>
</fullquery>

   <fullquery name="content_extlink::edit.extlink_update_object">      
      <querytext>

        update acs_objects
        set last_modified = current_timestamp,
          modifying_user = :modifying_user,
          modifying_ip = :modifying_ip,
          title = :label
        where object_id = :extlink_id

      </querytext>
   </fullquery>

   <fullquery name="content_extlink::edit.extlink_update_extlink">      
      <querytext>

        update cr_extlinks
        set url = :url,
          label = :label,
          description = :description
        where extlink_id = :extlink_id

      </querytext>
   </fullquery>

   <fullquery name="content_extlink::extlink_name.extlink_name">      
      <querytext>
          select label
          from cr_extlinks
          where extlink_id = :item_id
      </querytext>
   </fullquery>


</queryset>
