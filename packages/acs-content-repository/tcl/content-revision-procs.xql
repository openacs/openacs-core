<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN"
"http://www.thecodemill.biz/repository/xql.dtd">
<!--  -->
<!-- @author Dave Bauer (dave@thedesignexperience.org) -->
<!-- @creation-date 2005-02-09 -->
<!-- @arch-tag: 77403e40-f44c-4cf4-a036-319a6bcf580d -->
<!-- @cvs-id $Id$ -->

<queryset>
  <fullquery name="content::revision::update_content.update_content">
    <querytext>
      update cr_revisions set content=:content where
      revision_id=:revision_id
    </querytext>
  </fullquery>
</queryset>