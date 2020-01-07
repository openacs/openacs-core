<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="groups_select">      
      <querytext>
      
    select my_view.group_name, my_view.group_id
    from (select /*+ ORDERED */ DISTINCT  g.group_name, g.group_id
           from acs_objects o, groups g,
                application_group_element_map app_group, 
                acs_object_party_privilege_map perm
          where perm.object_id = g.group_id
            and perm.party_id = :user_id
            and perm.privilege = 'read'
            and g.group_id = o.object_id
            and o.object_type = :group_type
            and app_group.package_id = :package_id
            and app_group.element_id = g.group_id
          order by lower(g.group_name)) my_view 
    where rownum <= 26

      </querytext>
</fullquery>

</queryset>
