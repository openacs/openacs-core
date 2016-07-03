<?xml version="1.0"?>
<queryset>

<fullquery name="select_groups">      
      <querytext>
      
    select DISTINCT g.group_id, g.group_name
      from (select group_id, group_name 
              from groups g, acs_objects o 
             where g.group_id = o.object_id 
               and o.object_type = :group_type) g, 
           application_group_element_map m
     where m.package_id = :package_id
       and m.element_id = g.group_id
       and acs_permission__permission_p(g.group_id, :user_id, 'read')         

     order by lower(g.group_name)

      </querytext>
</fullquery>

 
</queryset>
