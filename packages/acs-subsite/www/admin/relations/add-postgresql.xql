<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="rel_type_info">      
      <querytext>
    select t.object_type_two, t.role_two as role, 
           acs_rel_type__role_pretty_name(t.role_two) as role_pretty_name,
           acs_object_type__pretty_name(t.object_type_two) as object_type_two_name,
           ancestor_rel_types.object_type as ancestor_rel_type
      from acs_rel_types t, acs_object_types obj_types, 
           acs_object_types ancestor_rel_types
     where t.rel_type = :rel_type
       and t.rel_type = obj_types.object_type
       and ancestor_rel_types.supertype = 'relationship'
       and ancestor_rel_types.object_type in (
	      	select t2.object_type from 
		acs_object_types t1, acs_object_types t2
		where t1.object_type= :rel_type
		and t1.tree_sortkey between t2.tree_sortkey and tree_right(t2.tree_sortkey)
	)

      </querytext>
</fullquery>

 
<partialquery name="select_parties_scope_query">
<querytext>
cross join (select element_id from application_group_element_map
   where package_id = :package_id) app_elements
</querytext>
</partialquery>

<fullquery name="select_parties">      
      <querytext>
            select DISTINCT
                   case when groups.group_id is null then
                          case when persons.person_id is null then 'INVALID' 
				else persons.first_names || ' ' || persons.last_name 
			  end else
                   groups.group_name end as party_name,
                   p.party_id
            from (select o.object_id as party_id
                  from acs_objects o,
                       (select ot2.object_type from acs_object_types ot, acs_object_types ot2
                        where ot2.tree_sortkey between ot.tree_sortkey and tree_right(ot.tree_sortkey)
                          and $start_with) t
                  where o.object_type = t.object_type) p left join
                 (select element_id
                  from group_element_map
                  where group_id = :group_id and rel_type = :rel_type
                  UNION ALL
                  select :group_id::integer ) m on (p.party_id = m.element_id) cross join
                 (select party_id
                  from rc_parties_in_required_segs
                  where group_id = :group_id 
                    and rel_type = :rel_type) pirs $scope_query left join
                 groups on (p.party_id = groups.group_id) 
		left join persons on (p.party_id = persons.person_id)
            where 
              m.element_id is null
              and p.party_id = pirs.party_id $scope_clause
    
      </querytext>
</fullquery>

 
</queryset>
