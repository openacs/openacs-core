<?xml version="1.0"?>
<queryset>

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

<fullquery name="all_group_membership">
  <querytext>
    select distinct lower(groups.group_name) as group_name
      from groups, group_member_map gm
     where groups.group_id = gm.group_id and gm.member_id=:user_id
  order by lower(groups.group_name)
  </querytext>
</fullquery>

<fullquery name="direct_group_membership">
  <querytext>
  select group_id, rel_id, party_names.party_name as group_name
    from (select /*+ ORDERED */ DISTINCT rels.rel_id, object_id_one as group_id, 
                 object_id_two
            from acs_rels rels
           where rels.rel_type = 'membership_rel'
                 and rels.object_id_two = :user_id) r, 
         party_names 
   where r.group_id = party_names.party_id
order by lower(party_names.party_name)
  </querytext> 
</fullquery>
</queryset>
