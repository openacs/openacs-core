<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

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


</queryset>
