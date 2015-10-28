<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="email_image::new_item.new_lob_size">
      <querytext>
        update cr_revisions 
	set content_length = lob_length(lob)
        where revision_id = :revision_id
      </querytext>
</fullquery>

<fullquery name="email_image::new_item.new_lob_content">
      <querytext>
        update cr_revisions
        set mime_type = :mime_type,
        lob = [set __lob_id [db_string get_lob_id "select empty_lob()"]]
        where revision_id = :revision_id
     </querytext>
</fullquery>


<fullquery name="email_image::edit_email_image.lob_size">
      <querytext>
        update cr_revisions 
	set content_length = lob_length(lob)
        where revision_id = :revision_id
      </querytext>
</fullquery>

<fullquery name="email_image::edit_email_image.lob_content">
      <querytext>
        update cr_revisions
        set mime_type = :mime_type,
        lob = [set __lob_id [db_string get_lob_id "select empty_lob()"]]
        where revision_id = :revision_id
     </querytext>
</fullquery>

<fullquery name="email_image::add_relation.add_relation">
     <querytext>
	select acs_rel__new (
        null,
        'email_image_rel',
        :user_id,
        :item_id,
        null,
        null,
        null
        )
     </querytext>
</fullquery>

</queryset>
