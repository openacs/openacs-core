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
    <version>8.1.7</version>
  </rdbms>
  <fullquery name="content::revision::update_content.update_content">
    <querytext>
        update cr_revisions
        set    content = empty_blob()
        where  revision_id = :revision_id
        returning content into :1
    </querytext>
  </fullquery>
  
</queryset>