<?xml version="1.0"?>
<queryset>

    <fullquery name="site_node::mount.mount_object">
        <querytext>
            update site_nodes
            set object_id = :object_id
            where node_id = :node_id
        </querytext>
    </fullquery>

    <fullquery name="site_node::unmount.unmount_object">
        <querytext>
            update site_nodes
            set object_id = null
            where node_id = :node_id
        </querytext>
    </fullquery>

    <fullquery name="site_node_mount_application.get_context">      
        <querytext>
            select object_id as context_id
            from site_nodes 
            where node_id = :parent_node_id
        </querytext>
    </fullquery>

    
    <fullquery name="site_map_unmount_application.unmount">      
        <querytext>
            update site_nodes
            set object_id = null
            where node_id = :node_id
        </querytext>
    </fullquery>

</queryset>
