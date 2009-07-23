<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN"
"http://www.thecodemill.biz/repository/xql.dtd">
<!--  -->
<!-- @author Dave Bauer (dave@thedesignexperience.org) -->
<!-- @creation-date 2005-02-09 -->
<!-- @arch-tag: 7db5e029-8e8c-46a5-b178-e405a6875116 -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  <rdbms>
    <type>oracle</type>
    <version>8.1.6</version>
  </rdbms>
  <fullquery name="content::revision::update_content.update_content">
    <querytext>
        update cr_revisions
        set    content = empty_blob()
        where  revision_id = :revision_id
        returning content into :1
    </querytext>
  </fullquery>

  <fullquery name="content::revision::new.update_lob_attribute">
    <querytext>
		update $lob_table
		set $lob_attribute = empty_clob()
		where $lob_id_column = :revision_id
		returning $lob_attribute into :1
    </querytext>
  </fullquery>

  <fullquery name="content::revision::item_id.item_id">
    <querytext>
      select item_id
      from cr_revisions
      where revision_id = :revision_id
    </querytext>
  </fullquery>

  <fullquery name="content::revision::update_content.set_lob_size">      
      <querytext>

         update cr_revisions
         set content_length = lob_length(lob)
         where revision_id = :revision_id

      </querytext>
  </fullquery>

  <fullquery name="content::revision::update_content.set_file_content">
      <querytext>
          update cr_revisions
          set filename = :filename,
              mime_type = :mime_type,
              content_length = :tmp_size
          where revision_id = :revision_id
      </querytext>
  </fullquery>

  <fullquery name="content::revision::get_cr_file_path.get_storage_key_and_path">
    <querytext>	
      select storage_area_key, 
          filename
      from cr_items ci, 
          cr_revisions cr 
      where cr.item_id=ci.item_id 
          and cr.revision_id=:revision_id
    </querytext>
  </fullquery>
  
</queryset>

