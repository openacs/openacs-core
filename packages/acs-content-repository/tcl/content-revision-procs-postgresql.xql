<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN"
"http://www.thecodemill.biz/repository/xql.dtd">
<!--  -->
<!-- @author Dave Bauer (dave@thedesignexperience.org) -->
<!-- @creation-date 2005-02-09 -->
<!-- @arch-tag: 8fc5c63c-02e7-4910-a536-8edbaff68ff8 -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  <rdbms>
    <type>postgresql</type>
    <version>7.3</version>
  </rdbms>
  
  <fullquery name="content::revision::update_content.update_content">
    <querytext>
      update cr_revisions set content=:content where
      revision_id=:revision_id
    </querytext>
  </fullquery>

  <fullquery name="content::revision::item_id.item_id">
    <querytext>
      select item_id
      from cr_revisions
      where revision_id = :revision_id
    </querytext>
  </fullquery>

</queryset>