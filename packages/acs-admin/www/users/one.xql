<?xml version="1.0"?>
<queryset>

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
