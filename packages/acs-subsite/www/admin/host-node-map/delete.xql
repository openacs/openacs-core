<?xml version="1.0"?>

<queryset>

<fullquery name="host_node_delete">
    <querytext>

    delete from host_node_map 
    where host = :host
    and node_id = :node_id

    </querytext>
</fullquery>

</queryset>
