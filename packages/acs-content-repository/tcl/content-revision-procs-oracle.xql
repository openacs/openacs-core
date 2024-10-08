<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN"
"http://www.thecodemill.biz/repository/xql.dtd">
<!--  -->
<!-- @author Dave Bauer (dave@thedesignexperience.org) -->
<!-- @creation-date 2005-02-09 -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  <rdbms>
    <type>oracle</type>
    <version>8.1.6</version>
  </rdbms>
  <fullquery name="content::revision::update_content-text.update_content">
    <querytext>
        update cr_revisions
        set    content = empty_blob()
        where  revision_id = :revision_id
        returning content into :1
    </querytext>
  </fullquery>

  <fullquery name="content::revision::update_content-lob.update_content">
    <querytext>
        update cr_revisions
        set    content = empty_blob()
        where  revision_id = :revision_id
        returning content into :1
    </querytext>
  </fullquery>
  
  <fullquery name="content::revision::item_id.item_id">
    <querytext>
      select item_id
      from cr_revisions
      where revision_id = :revision_id
    </querytext>
  </fullquery>

  <fullquery name="content::revision::update_content-lob.set_size">
      <querytext>

         update cr_revisions
         set content_length = lob_length(lob)
         where revision_id = :revision_id

      </querytext>
  </fullquery>


  <fullquery name="content::revision::update_content-lob.set_content">
      <querytext>

        update cr_revisions
        set mime_type = :mime_type,
        content = empty_blob()
        where revision_id = :revision_id

      </querytext>
  </fullquery>
  
  <fullquery name="content::revision::get_cr_file_path.get_storage_key_and_path">
    <querytext>	
      select storage_area_key, 
          filename
      from cr_items ci, cr_revisions cr 
      where cr.item_id=ci.item_id 
          and cr.revision_id=:revision_id
    </querytext>
  </fullquery>

  <fullquery name="content::revision::export_to_filesystem-lob.select_object_content">     
    <querytext>
      select content
      from cr_revisions
      where revision_id = :revision_id
    </querytext>
  </fullquery>  
  
</queryset>

