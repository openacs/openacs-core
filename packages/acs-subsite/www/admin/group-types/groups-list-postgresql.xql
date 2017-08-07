<?xml version="1.0"?>
<queryset>
  <rdbms><type>postgresql</type><version>9.0</version></rdbms>

<fullquery name="select_groups">      
  <querytext>
    select g.group_id, g.group_name from (
	select DISTINCT g.group_id, g.group_name
        from (select group_id, group_name 
              from groups g, acs_objects o 
             where g.group_id = o.object_id 
               and o.object_type = :group_type) g, 
           application_group_element_map m
        where m.package_id = :package_id
        and m.element_id = g.group_id
        and acs_permission.permission_p(g.group_id, :user_id, 'read')
	) g
     order by lower(g.group_name)

      </querytext>
</fullquery>

 
</queryset>
