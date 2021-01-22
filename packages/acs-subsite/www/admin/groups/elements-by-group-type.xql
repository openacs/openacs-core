<?xml version="1.0"?>
<queryset>

<fullquery name="select_group_types">      
      <querytext>

    select
           t.object_type, t.pretty_name, count(g.group_id) as number_groups
      from groups g, acs_objects o, acs_object_types t,
           application_group_element_map app_group
     where o.object_id = g.group_id
       and o.object_type = t.object_type
       and app_group.package_id = :package_id
       and app_group.element_id = g.group_id
     group by t.object_type, t.pretty_name
     order by lower(t.pretty_name)

      </querytext>
</fullquery>

 
</queryset>
