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

  <fullquery name="content::item::upload_file.get_parent_existing_filenames">
  <querytext>
    select name
      from cr_items
     where parent_id = :parent_id
  </querytext>
</fullquery>

  <fullquery name="content::item::get.get_item_folder">
    <querytext>
      select cf.*,
      ci.name,
      ci.item_id,
      ci.live_revision,
      ci.latest_revision,
      ci.locale,
      ci.publish_status,
      ci.content_type,
      ci.storage_type
      from cr_folders cf,
      cr_items ci
      where ci.item_id = cf.folder_id
      and ci.item_id = :item_id
    </querytext>
  </fullquery>
    
  <fullquery name="content::item::upload_file.get_parent_existing_filenames">
  <querytext>
    select name
      from cr_items
     where parent_id = :parent_id
  </querytext>
</fullquery>

  <fullquery name="content::item::get_id_by_name.get_item_id_by_name">
  <querytext>
    select item_id
      from cr_items
     where name = :name
     and parent_id = :parent_id
  </querytext>
</fullquery>

</queryset>
