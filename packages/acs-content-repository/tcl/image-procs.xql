<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN"
"http://www.thecodemill.biz/repository/xql.dtd">
<!--  -->
<!-- @author Dave Bauer (dave@thedesignexperience.org) -->
<!-- @creation-date 2006-08-29 -->
<!-- @arch-tag: 47baf88a-8fad-43bc-8b02-059315c80e00 -->
<!-- @cvs-id $Id -->

<queryset>
  <fullquery name="image::get_resized_item_id.get_resized_item_id">
    <querytext>
      select child_id
      from cr_child_rels
      where parent_id=:item_id
      and relation_tag = 'image-' || :size_name
    </querytext>
  </fullquery>
</queryset>