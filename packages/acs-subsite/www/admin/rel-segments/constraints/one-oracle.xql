<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_constraint_properties">      
      <querytext>
      
    select c.constraint_id, c.constraint_name, c.rel_side, 
           s.segment_id, s.segment_name, s.rel_type, acs_group.name(s.group_id) as group_name,
           s2.segment_id as req_segment_id, s2.segment_name as req_segment_name, 
           s2.rel_type as req_rel_type, acs_group.name(s2.group_id) as req_group_name
      from application_group_segments s, application_group_segments s2,
           rel_constraints c
     where s.segment_id = c.rel_segment
       and s2.segment_id = c.required_rel_segment
       and c.constraint_id = :constraint_id
       and s.package_id = :package_id

      </querytext>
</fullquery>

 
<fullquery name="select_rel_type_info">      
      <querytext>
      
    select role1.role as role_one, 
           nvl(role1.pretty_name,'Object on side one') as role_one_pretty_name,
           nvl(role1.pretty_plural,'Objects on side one') as role_one_pretty_plural,
           role2.role as role_two, 
           nvl(role2.pretty_name,'Object on side two') as role_two_pretty_name,
           nvl(role2.pretty_plural,'Objects on side two') as role_two_pretty_plural,
           acs_object_type.pretty_name(rel.rel_type) as rel_type_pretty_name
      from acs_rel_types rel, acs_rel_roles role1, acs_rel_roles role2
     where rel.rel_type = :rel_type
       and rel.role_one = role1.role(+)
       and rel.role_two = role2.role(+)

      </querytext>
</fullquery>

 
</queryset>
