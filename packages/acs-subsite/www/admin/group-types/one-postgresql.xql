<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="groups_select">      
      <querytext>

    select my_view.group_name, my_view.group_id
    from (select DISTINCT g.group_name, g.group_id
           from acs_objects o, groups g,
                application_group_element_map app_group, 
                all_object_party_privilege_map perm
          where perm.object_id = g.group_id
            and perm.party_id = :user_id
            and perm.privilege = 'read'
            and g.group_id = o.object_id
            and o.object_type = :group_type
            and app_group.package_id = :package_id
            and app_group.element_id = g.group_id
          order by g.group_name, g.group_id) my_view 
    limit 26

      </querytext>
</fullquery>

 
<fullquery name="attributes_select">      
      <querytext>

    select a.attribute_id, a.pretty_name, 
           a.ancestor_type, t.pretty_name as ancestor_pretty_name
      from acs_object_type_attributes a,
           (select t2.object_type, t2.pretty_name,
		   tree_level(t2.tree_sortkey) - tree_level(t1.tree_sortkey) + 1 as type_level		   	
              from acs_object_types t1, acs_object_types t2
	     where t1.object_type = 'group'
	       and t2.tree_sortkey between t1.tree_sortkey and tree_right(t1.tree_sortkey)) t
     where a.object_type = :group_type
       and t.object_type = a.ancestor_type
    order by type_level 

      </querytext>
</fullquery>

 
</queryset>
