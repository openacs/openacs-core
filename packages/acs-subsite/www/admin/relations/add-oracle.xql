<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="rel_type_info">      
      <querytext>
      
    select t.object_type_two, t.role_two as role, 
           acs_rel_type.role_pretty_name(t.role_two) as role_pretty_name,
           acs_object_type.pretty_name(t.object_type_two) as object_type_two_name,
           ancestor_rel_types.object_type as ancestor_rel_type
      from acs_rel_types t, acs_object_types obj_types, 
           acs_object_types ancestor_rel_types
     where t.rel_type = :rel_type
       and t.rel_type = obj_types.object_type
       and ancestor_rel_types.supertype = 'relationship'
       and ancestor_rel_types.object_type in (
               select object_type from acs_object_types
               start with object_type = :rel_type
               connect by object_type = prior supertype
           )

      </querytext>
</fullquery>

<partialquery name="select_parties_scope_query">
<querytext>
, (select element_id from application_group_element_map
   where package_id = :package_id) app_elements
</querytext>
</partialquery>

<fullquery name="select_parties">      
      <querytext>
      
            select DISTINCT
                   decode(groups.group_id,
                          null, case when persons.person_id = null then 'INVALID' else persons.first_names || ' ' || persons.last_name end,
                          groups.group_name) as party_name,
                   p.party_id
            from (select o.object_id as party_id
                  from acs_objects o,
                       (select object_type from acs_object_types ot
                        start with $start_with
                        connect by prior ot.object_type = ot.supertype) t
                  where o.object_type = t.object_type) p,
                 (select element_id
                  from group_element_map
                  where group_id = :group_id and rel_type = :rel_type
                  UNION ALL
                  select to_number(:group_id) from dual) m,
                 (select party_id
                  from rc_parties_in_required_segs
                  where group_id = :group_id 
                    and rel_type = :rel_type) pirs $scope_query,
                 groups,
                 persons
            where p.party_id = m.element_id(+)
              and m.element_id is null
              and p.party_id = pirs.party_id $scope_clause
              and p.party_id = groups.group_id(+)
              and p.party_id = persons.person_id(+)
    
      </querytext>
</fullquery>

 
</queryset>
