<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="site_node::delete.delete_site_node">
        <querytext>
            begin site_node.delete(:node_id); end;
        </querytext>
    </fullquery>

    <fullquery name="site_node::init_cache.select_site_nodes">
        <querytext>
            select site_node.url(site_nodes.node_id) as url,
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
            from site_nodes,
                 apm_packages
            where site_nodes.object_id = apm_packages.package_id(+)
        </querytext>
    </fullquery>

    <fullquery name="site_node::update_cache.select_site_node">
        <querytext>
            select site_node.url(site_nodes.node_id) as url,
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
            from site_nodes,
                 apm_packages
            where site_nodes.node_id = :node_id
            and site_nodes.object_id = apm_packages.package_id(+)
        </querytext>
    </fullquery>

    <fullquery name="site_node::get_url_from_object_id.select_url_from_object_id">
        <querytext>
            select site_node.url(node_id)
            from site_nodes
            where object_id = :object_id
        </querytext>
    </fullquery>

</queryset>
