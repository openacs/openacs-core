<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN"
"http://www.thecodemill.biz/repository/xql.dtd">
<!--  -->
<!-- @author Dave Bauer (dave@thedesignexperience.org) -->
<!-- @creation-date 2005-01-09 -->
<!-- @arch-tag: 47baf88a-8fad-43bc-8b02-059315c80e00 -->
<!-- @cvs-id $Id$ -->

<queryset>
  <fullquery name="content::item::get.get_item">
    <querytext>
      select cx.*,
      ci.live_revision,
      ci.latest_revision,
      ci.locale,
      ci.publish_status,
      ci.content_type,
      ci.storage_type
      from ${table_name} cx,
      cr_items ci
      where ci.${revision}_revision = cx.revision_id
      and ci.item_id = :item_id
    </querytext>
  </fullquery>
</queryset>