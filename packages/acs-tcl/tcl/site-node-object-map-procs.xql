<?xml version="1.0"?>

<queryset>

    <fullquery name="site_node_object_map::get_node_id.select_node_mapping">
        <querytext>
            select node_id
            from site_node_object_mappings
            where object_id = :object_id
        </querytext>
    </fullquery>

</queryset>
