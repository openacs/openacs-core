<?xml version="1.0"?>
<queryset>
  <rdbms><type>postgresql</type><version>9.0</version></rdbms>

<fullquery name="rel_type_info">      
      <querytext>

    select object_type as ancestor_rel_type
      from acs_object_types
     where supertype = 'relationship'
       and object_type in (
               select t2.object_type
	         from acs_object_types t1, acs_object_types t2
		where t1.tree_sortkey between t2.tree_sortkey and tree_right(t2.tree_sortkey)
		  and t1.object_type = :rel_type
	   )

      </querytext>
</fullquery>
  
<fullquery name="relations_query">      
      <querytext>

select r.rel_id, 
       party_names.party_name as element_name
from (select DISTINCT rels.rel_id, object_id_two
      from $extra_tables acs_rels rels
      where rels.rel_type = :rel_type
        and rels.object_id_one = :group_id $extra_where_clauses) r, 
     party_names 
where r.object_id_two = party_names.party_id
and   acs_permission.permission_p(r.rel_id, :user_id, 'read')         

order by element_name

      </querytext>
</fullquery>

 
</queryset>
