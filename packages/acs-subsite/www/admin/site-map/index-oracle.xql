<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="path_select">
        <querytext>
            select node_id,
                   name,
                   directory_p,
                   level,
                   acs_object.name(object_id) as obj_name,
                   acs_permission.permission_p(object_id, :user_id, 'admin') as admin_p
            from site_nodes
            start with node_id = :root_id
            connect by node_id = prior parent_id
            order by level desc
        </querytext>
    </fullquery>

    <fullquery name="nodes_select">
        <querytext>
            select package_id,
                   package_key,
                   (select pretty_name from apm_package_types where package_key = p.package_key) as package_pretty_name,
                   apm_package_type.num_parameters(package_key) parameter_count,
                   node_id,
                   url,
                   parent_url,
                   name,
                   root_p,
                   mylevel - 1 as mylevel,
                   object_id,
                   object_name,
                   directory_p,
                   parent_id,
                   n_children,
                   decode(acs_permission.permission_p(object_id, :user_id, 'admin'), 't', 1, 0) object_admin_p
            from apm_packages p,
                 (select node_id,
                         site_node.url(node_id) as url,
                         site_node.url(parent_id) as parent_url,
                         name,
                         (select count(*)
                          from site_nodes
                          where parent_id = n.node_id) as n_children,
                         decode(node_id, site_node.node_id('/'), 1, 0) as root_p,
                         level as mylevel,
                         object_id,
                         acs_object.name(object_id) as object_name,
                         directory_p,
                         parent_id
                  from site_nodes n
                  where (object_id is null
                  or acs_permission.permission_p(object_id, :user_id, 'read') = 't')
            start with node_id = nvl(:root_id, site_node.node_id('/'))
            connect by prior node_id = parent_id and parent_id in ([join $expand ", "])) site_map
            where site_map.object_id = p.package_id (+)
            order by url
        </querytext>
    </fullquery>

    <fullquery name="package_types">
        <querytext>
            select package_key,
                   pretty_name
            from apm_package_types
            where not (apm_package.singleton_p(package_key) = 1
            and apm_package.num_instances(package_key) >= 1)
            order by pretty_name
        </querytext>
    </fullquery>

    <fullquery name="services_select">
        <querytext>
            select package_id,
                   ap.package_key,
                   acs_object.name(package_id) as instance_name,
                   apm_package_type.num_parameters(ap.package_key) as parameter_count
            from apm_packages ap,
                 apm_package_types
            where ap.package_key = apm_package_types.package_key
            and package_type = 'apm_service'
            and (
                    acs_permission.permission_p(package_id, :user_id, 'read') = 't'
                 or acs_permission.permission_p(package_id, acs.magic_object_id('the_public'), 'read') = 't'
                )
            order by instance_name
        </querytext>
    </fullquery>

</queryset>
