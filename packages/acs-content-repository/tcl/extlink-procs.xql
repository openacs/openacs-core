<?xml version="1.0"?>
<queryset>

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
