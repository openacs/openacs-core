<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

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

   <fullquery name="content_extlink::edit.extlink_update_object">      
      <querytext>

        update acs_objects
        set last_modified = sysdate,
          modifying_user = :modifying_user,
          modifying_ip = :modifying_ip,
          title = :label
        where object_id = :extlink_id

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

</queryset>
