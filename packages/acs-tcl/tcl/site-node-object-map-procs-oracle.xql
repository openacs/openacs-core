<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="site_node_object_map::new.set_node_mapping">
        <querytext>
            declare
            begin
                site_node_object_map.new(object_id => :object_id, node_id => :node_id);
            end;
        </querytext>
    </fullquery>

    <fullquery name="site_node_object_map::del.unset_node_mapping">
        <querytext>
            declare
            begin
                site_node_object_map.del(object_id => :object_id);
            end;
        </querytext>
    </fullquery>

</queryset>
