<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

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

   <fullquery name="content_symlink::edit.symlink_update_object">      
      <querytext>

        update acs_objects
        set last_modified = sysdate,
          modifying_user = :modifying_user,
          modifying_ip = :modifying_ip,
          title = :label
        where object_id = :symlink_id

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


</queryset>
