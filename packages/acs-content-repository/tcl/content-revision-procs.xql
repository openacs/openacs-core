<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN"
"http://www.thecodemill.biz/repository/xql.dtd">
<!--  -->
<!-- @author Dave Bauer (dave@thedesignexperience.org) -->
<!-- @creation-date 2005-02-09 -->
<!-- @arch-tag: 8fc5c63c-02e7-4910-a536-8edbaff68ff8 -->
<!-- @cvs-id $Id$ -->

<queryset>

  <fullquery name="content::revision::new.get_storage_type">
    <querytext>
	select storage_type from cr_items where item_id=:item_id
    </querytext>
  </fullquery>
</queryset>
