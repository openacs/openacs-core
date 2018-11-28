<?xml version="1.0"?>
<queryset>

    <fullquery name="site_node::mount.mount_object">
        <querytext>
            update site_nodes
            set object_id = :object_id
            where node_id = :node_id
        </querytext>
    </fullquery>

    <fullquery name="site_node::mount.update_object_package_id">
        <querytext>
            update acs_objects
            set package_id = :object_id
            where object_id = :node_id
        </querytext>
    </fullquery>


    <fullquery name="site_node::rename.rename_node">
        <querytext>
            update site_nodes
            set    name = :name
            where  node_id = :node_id
        </querytext>
    </fullquery>

    <fullquery name="site_node::rename.update_object_title">
        <querytext>
            update acs_objects
            set    title = :name
            where  object_id = :node_id
        </querytext>
    </fullquery>

    <fullquery name="site_node::unmount.unmount_object">
        <querytext>
            update site_nodes
            set object_id = null
            where node_id = :node_id
        </querytext>
    </fullquery>

    <fullquery name="site_node::unmount.update_object_package_id">
        <querytext>
            update acs_objects
            set package_id = null
            where object_id = :node_id
        </querytext>
    </fullquery>

</queryset>
