<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="site_node_object_map::new.set_node_mapping">
        <querytext>
            select site_node_object_map__new(:object_id, :node_id)
        </querytext>
    </fullquery>

    <fullquery name="site_node_object_map::del.unset_node_mapping">
        <querytext>
            select site_node_object_map__del(:object_id)
        </querytext>
    </fullquery>

</queryset>
