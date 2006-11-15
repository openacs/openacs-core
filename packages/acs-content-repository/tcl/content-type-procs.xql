<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN"
"http://www.thecodemill.biz/repository/xql.dtd">
<!--  -->
<!-- @author Dave Bauer (dave@thedesignexperience.org) -->
<!-- @creation-date 2005-02-09 -->
<!-- @arch-tag: 8fc5c63c-02e7-4910-a536-8edbaff68ff8 -->
<!-- @cvs-id $Id$ -->

<queryset>

  <fullquery name="content::type::content_type_p_not_cached.content_type_p">
    <querytext>
        select 1
        from cr_content_mime_type_map
        where mime_type = :mime_type
        and content_type = :content_type
    </querytext>
  </fullquery>
</queryset>
