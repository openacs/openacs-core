<?xml version="1.0"?>
<queryset>

<fullquery name="relations_query">      
      <querytext>
      FIX ME REMOVE OPTIMIZATION HINT

select r.rel_id, 
       party_names.party_name as element_name
from (select /*+ ORDERED */ DISTINCT rels.rel_id, object_id_two
      from $extra_tables acs_rels rels, all_object_party_privilege_map perm
      where perm.object_id = rels.rel_id
        and perm.party_id = :user_id
        and perm.privilege = 'read'
        and rels.rel_type = :rel_type
        and rels.object_id_one = :group_id $extra_where_clauses) r, 
     party_names 
where r.object_id_two = party_names.party_id
order by lower(element_name)

      </querytext>
</fullquery>

 
</queryset>
