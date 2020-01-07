<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="groups_select">      
      <querytext>

    select my_view.group_name, my_view.group_id
    from (select DISTINCT g.group_name, g.group_id
           from acs_objects o, groups g,
                application_group_element_map app_group
          where g.group_id = o.object_id
            and o.object_type = :group_type
            and (app_group.package_id = :package_id and app_group.element_id = g.group_id or o.object_id = -2)
	    and acs_permission__permission_p(g.group_id, :user_id, 'read')	   
          order by g.group_name, g.group_id) my_view 
    limit 26

      </querytext>
</fullquery>

</queryset>
