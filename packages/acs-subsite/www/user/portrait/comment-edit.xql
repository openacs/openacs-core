<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "http://www.thecodemill.biz/repository/xql.dtd">
<!-- packages/acs-subsite/www/user/portrait/comment-edit.xql -->
<!-- @author Emmanuelle Raffenne (eraffenne@dia.uned.es) -->
<!-- @creation-date 2007-11-27 -->
<!-- @arch-tag: d51369f7-896b-494e-8f83-92366f1a5349 -->
<!-- @cvs-id $Id$ -->

<queryset>

  <fullquery name="user_info">
    <querytext>
      select first_names, last_name
      from persons
      where person_id = :user_id
    </querytext>
  </fullquery>


  <fullquery name="portrait_info">
    <querytext>
      select description
      from cr_revisions
      where revision_id = (select live_revision
      from cr_items c, acs_rels a
      where c.item_id = a.object_id_two
      and a.object_id_one = :user_id
      and a.rel_type = 'user_portrait_rel')
    </querytext>
  </fullquery>

  <fullquery name="comment_update">
    <querytext>
      update cr_revisions
      set description=:description
      where revision_id = (select live_revision
        from acs_rels a, cr_items c
        where a.object_id_two = c.item_id
          and a.object_id_one = :user_id
          and a.rel_type = 'user_portrait_rel')
    </querytext>
  </fullquery>

</queryset>