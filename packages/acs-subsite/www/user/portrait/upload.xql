<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "http://www.thecodemill.biz/repository/xql.dtd">
<!-- packages/acs-subsite/www/user/portrait/upload.xql -->
<!-- @author Emmanuelle Raffenne (eraffenne@dia.uned.es) -->
<!-- @creation-date 2007-11-21 -->
<!-- @arch-tag: 136be82f-a97a-44ec-ba75-939bdcad0004 -->
<!-- @cvs-id $Id$ -->

<queryset>

  <fullquery name="checkportrait">
    <querytext>
      SELECT live_revision as revision_id, item_id
          FROM acs_rels a, cr_items c
          WHERE a.object_id_two = c.item_id
          AND a.rel_type = 'user_portrait_rel'
          AND a.object_id_one = :current_user_id
          AND c.live_revision is not NULL
    </querytext>
  </fullquery>

  <fullquery name="getstory">
    <querytext>
      select description 
      from cr_revisions 
      where revision_id = :revision_id
    </querytext>
  </fullquery>

  <fullquery name="get_name">
    <querytext>
      select first_names, last_name
      from persons 
      where person_id=:user_id
    </querytext>
  </fullquery>

</queryset>
