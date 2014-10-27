# /packages/acs-subsite/www/admin/group-types/groups-list.tcl

# sets up datasource for groups-list.adp

if { (![info exists group_type] || $group_type eq "") } {
    error "Group type must be specified"
}

set user_id [ad_conn user_id]

set package_id [ad_conn package_id]

db_multirow groups select_groups {
    select DISTINCT g.group_id, g.group_name
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
     order by lower(g.group_name)
}

ad_return_template
