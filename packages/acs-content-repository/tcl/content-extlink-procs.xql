<?xml version="1.0"?>
<queryset>

   <fullquery name="content::extlink::edit.extlink_update_extlink">      
      <querytext>

        update cr_extlinks
        set url = :url,
          label = :label,
          description = :description
        where extlink_id = :extlink_id

      </querytext>
   </fullquery>

   <fullquery name="content::extlink::edit.extlink_update_object">      
      <querytext>

        update acs_objects
        set last_modified = current_timestamp,
          modifying_user = :modifying_user,
          modifying_ip = :modifying_ip,
          title = :label
        where object_id = :extlink_id

      </querytext>
   </fullquery>

   <fullquery name="content::extlink::name.get">      
      <querytext>
          select label
          from cr_extlinks
          where extlink_id = :item_id
      </querytext>
   </fullquery>

</queryset>
