<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="site_node::delete.delete_site_node">
        <querytext>
            select site_node__delete(:node_id);
        </querytext>
    </fullquery>

    <fullquery name="site_node::init_cache.select_site_nodes">
        <querytext>
            select site_node__url(site_nodes.node_id) as url,
                   site_nodes.node_id,
                   site_nodes.parent_id,
                   site_nodes.directory_p,
                   site_nodes.pattern_p,
                   site_nodes.object_id,
                   (select acs_objects.object_type
                    from acs_objects
                    where acs_objects.object_id = site_nodes.object_id) as object_type,
                   apm_packages.package_key,
                   apm_packages.package_id
            from site_nodes left join apm_packages on site_nodes.object_id = apm_packages.package_id
        </querytext>
    </fullquery>

    <fullquery name="site_node::update_cache.select_site_node">
        <querytext>
            select site_node__url(site_nodes.node_id) as url,
                   site_nodes.node_id,
                   site_nodes.parent_id,
                   site_nodes.directory_p,
                   site_nodes.pattern_p,
                   site_nodes.object_id,
                   (select acs_objects.object_type
                    from acs_objects
                    where acs_objects.object_id = site_nodes.object_id) as object_type,
                   apm_packages.package_key,
                   apm_packages.package_id
            from site_nodes left join apm_packages on site_nodes.object_id = apm_packages.package_id
            where site_nodes.node_id = :node_id
        </querytext>
    </fullquery>

    <fullquery name="site_node_closest_ancestor_package_url.select_url">
        <querytext>
            select site_node__url(node_id)
            from site_nodes
            where object_id = :subsite_pkg_id
        </querytext>
    </fullquery>

</queryset>
