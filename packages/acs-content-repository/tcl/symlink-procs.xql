<?xml version="1.0"?>
<queryset>

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

</queryset>
