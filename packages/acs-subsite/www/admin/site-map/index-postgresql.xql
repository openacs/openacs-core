<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="path_select">
        <querytext>
            select s2.node_id,
                   s2.name,
                   s2.directory_p,
                   tree_level(s2.tree_sortkey) as level,
                   acs_object__name(s2.object_id) as obj_name,
                   acs_permission__permission_p(s2.object_id, :user_id, 'admin') as admin_p
            from (select tree_ancestor_keys(site_node_get_tree_sortkey(:root_id)) as tree_sortkey) parents,
                 site_nodes s2
            where s2.tree_sortkey = parents.tree_sortkey
            order by level
        </querytext>
    </fullquery>

    <fullquery name="nodes_select">
        <querytext>
            select package_id,
                   package_key,
                   pretty_name as package_pretty_name,
                   apm_package_type__num_parameters(package_key) as parameter_count,
                   node_id, url, parent_url, name, root_p, mylevel, object_id,
                   object_name, directory_p, parent_id, n_children,
                   (select case when acs_permission__permission_p(object_id, :user_id, 'admin') = 't' then 1 else 0 end) as object_admin_p
            from apm_packages p join apm_package_types using (package_key) right outer join
                 (select n.node_id,
                         site_node__url(n.node_id) as url,
                         site_node__url(n.parent_id) as parent_url,
                         n.name,
                         (select count(*)
                          from site_nodes
                          where parent_id = n.node_id) as n_children,
                         case when n.node_id = site_node__node_id('/', null) then 1 else 0 end as root_p,
                         (select tree_level(n.tree_sortkey) - tree_level(n2.tree_sortkey)
                          from site_nodes n2
                          where n2.node_id = coalesce(:root_id, site_node__node_id('/', null))) as mylevel,
                         n.object_id,
                         acs_object__name(n.object_id) as object_name,
                         n.directory_p,
                         n.parent_id
                  from site_nodes n, site_nodes n2
                  where (n.object_id is null or acs_permission__permission_p(n.object_id, :user_id, 'read'))
                  and n2.node_id = coalesce(:root_id, site_node__node_id('/', null))
                  and n.tree_sortkey between n2.tree_sortkey and tree_right(n2.tree_sortkey)
                  and (n.parent_id is null or n.parent_id in ([join $expand ", "]))) site_map
            on site_map.object_id = p.package_id
            order by url
        </querytext>
    </fullquery>

    <fullquery name="package_types">
        <querytext>
            select package_key,
                   pretty_name
            from apm_package_types
            where not (apm_package__singleton_p(package_key) = 1 and apm_package__num_instances(package_key) >= 1)
            order by pretty_name
        </querytext>
    </fullquery>

    <fullquery name="services_select">
        <querytext>
            select package_id,
                   ap.package_key,
                   acs_object__name(package_id) as instance_name,
                   apm_package_type__num_parameters(ap.package_key) as parameter_count
            from apm_packages ap,
                 apm_package_types
            where ap.package_key = apm_package_types.package_key
            and package_type = 'apm_service'
            and (
                    acs_permission__permission_p(package_id, :user_id, 'read') = 't'
                 or acs_permission__permission_p(package_id, acs__magic_object_id('the_public'), 'read') = 't'
                )
            order by instance_name
        </querytext>
    </fullquery>

</queryset>
