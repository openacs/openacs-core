<?xml version="1.0"?>
<queryset>
<rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="email_image::new_item.lob_size">
      <querytext>
        update cr_revisions
        set content_length = dbms_lob.getlength(content)
        where revision_id = :revision_id
     </querytext>
</fullquery>

<fullquery name="email_image::new_item.lob_content">
      <querytext>
        update cr_revisions
        set    content = empty_blob()
        where  revision_id = :revision_id
        returning content into :1
     </querytext>
</fullquery>

<fullquery name="email_image::edit_email_image.lob_size">
      <querytext>
        update cr_revisions
        set content_length = dbms_lob.getlength(content)
        where revision_id = :revision_id
     </querytext>
</fullquery>

<fullquery name="email_image::edit_email_image.lob_content">
      <querytext>
        update cr_revisions
        set    content = empty_blob()
        where  revision_id = :revision_id
        returning content into :1
     </querytext>
</fullquery>

<fullquery name="email_image::add_relation.add_relation">
     <querytext>
        begin
          :1 := acs_rel.new (
                 rel_type => 'email_image_rel',
                 object_id_one => :user_id,
                 object_id_two => :item_id);
        end;
     </querytext>
</fullquery>

</queryset>
