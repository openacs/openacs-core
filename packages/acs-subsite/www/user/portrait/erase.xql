<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "http://www.thecodemill.biz/repository/xql.dtd">
<!-- packages/acs-subsite/www/user/portrait/erase.xql -->
<!-- @author Emmanuelle Raffenne (eraffenne@dia.uned.es) -->
<!-- @creation-date 2007-11-27 -->

<queryset>
  
  <fullquery name="get_item_id">
    <querytext>
      select object_id_two
      from acs_rels
      where object_id_one = :user_id
        and rel_type = 'user_portrait_rel'
    </querytext>
  </fullquery>

  <fullquery name="get_images">
    <querytext>
      select object_id 
      from acs_objects 
      where object_type in ('cr_item_child_rel','image') 
        and context_id = :item_id 
        and object_id not in (select live_revision from cr_items where item_id = :item_id)
    </querytext>
  </fullquery>

  <fullquery name="old_item_id">
    <querytext>
      select object_id 
      from acs_objects 
      where object_type = 'content_item' 
        and context_id = :item_id
    </querytext>
  </fullquery>

  <fullquery name="delete_rel">
    <querytext>
      delete from acs_rels 
      where object_id_two = :item_id 
        and object_id_one = :user_id 
        and rel_type = 'user_portrait_rel'
    </querytext>
  </fullquery>

</queryset>