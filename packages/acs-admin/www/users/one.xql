<?xml version="1.0"?>
<queryset>

<fullquery name="user_info">      
      <querytext>
      select first_names, last_name, email,
          coalesce(screen_name,'&lt none set up &gt') as screen_name,
          creation_date, creation_ip, last_visit, member_state, email_verified_p
      from cc_users
      where user_id = :user_id
      </querytext>
</fullquery>

 
<fullquery name="get_item_id">      
      <querytext>
      select live_revision as revision_id,
          coalesce(title,'view this portrait') as portrait_title
      from acs_rels a, cr_items c, cr_revisions cr 
      where a.object_id_two = c.item_id
         and c.live_revision = cr.revision_id
         and a.object_id_one = :user_id
         and a.rel_type = 'user_portrait_rel'
      </querytext>
</fullquery>

 
</queryset>
