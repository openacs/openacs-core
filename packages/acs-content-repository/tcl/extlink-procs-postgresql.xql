<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

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

</queryset>
