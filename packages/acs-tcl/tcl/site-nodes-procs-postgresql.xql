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
                   site_nodes.name,
                   site_nodes.directory_p,
                   site_nodes.pattern_p,
                   site_nodes.object_id,
                   (select acs_objects.object_type
                    from acs_objects
                    where acs_objects.object_id = site_nodes.object_id) as object_type,
                   apm_packages.package_key,
                   apm_packages.package_id,
                   apm_packages.instance_name,
                   apm_package_types.package_type
            from site_nodes left join 
                 apm_packages on site_nodes.object_id = apm_packages.package_id left join
                 apm_package_types using (package_key)
        </querytext>
    </fullquery>

    <fullquery name="site_node::update_cache.select_site_node">
        <querytext>
            select site_node__url(site_nodes.node_id) as url,
                   site_nodes.node_id,
                   site_nodes.parent_id,
                   site_nodes.name,
                   site_nodes.directory_p,
                   site_nodes.pattern_p,
                   site_nodes.object_id,
                   (select acs_objects.object_type
                    from acs_objects
                    where acs_objects.object_id = site_nodes.object_id) as object_type,
                   apm_packages.package_key,
                   apm_packages.package_id,
                   apm_packages.instance_name,
                   apm_package_types.package_type
            from site_nodes left join 
                 apm_packages on site_nodes.object_id = apm_packages.package_id left join
                 apm_package_types using (package_key)
            where site_nodes.node_id = :node_id
        </querytext>
    </fullquery>

    <fullquery name="site_node::get_url_from_object_id.select_url_from_object_id">
        <querytext>
            select site_node__url(node_id)
            from site_nodes
            where object_id = :object_id
            order by site_node__url(node_id) desc
        </querytext>
    </fullquery>

</queryset>
