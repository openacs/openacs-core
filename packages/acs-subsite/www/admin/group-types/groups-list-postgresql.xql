<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_groups">      
      <querytext>
      
  select g.group_id, g.group_name from (
    select distinct g.group_id, g.group_name
      from (select group_id, group_name
              from groups g, acs_objects o
             where g.group_id = o.object_id
		and o.object_type = :group_type) g,
           (select object_id
            from all_object_party_privilege_map
            where party_id = :user_id and privilege = 'read') perm,
           application_group_element_map m
     where perm.object_id = g.group_id
	and m.package_id = :package_id
	and m.element_id = g.group_id
     order by g.group_id, g.group_name) g
   order by lower(g.group_name)

      </querytext>
</fullquery>

 
</queryset>
