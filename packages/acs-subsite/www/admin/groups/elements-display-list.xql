<?xml version="1.0"?>
<queryset>

<fullquery name="relations_query">      
      <querytext>

select r.rel_id, 
       party_names.party_name as element_name
from (select DISTINCT rels.rel_id, object_id_two
      from $extra_tables acs_rels rels
      where acs_permission.permission_p(rels.rel_id, :user_id, 'read')
        and rels.rel_type = :rel_type
        and rels.object_id_one = :group_id $extra_where_clauses) r, 
     party_names 
where r.object_id_two = party_names.party_id
order by element_name

      </querytext>
</fullquery>

 
</queryset>
