<?xml version="1.0"?>

<queryset>

<fullquery name="host_node_insert">
    <querytext>

    insert into host_node_map 
    (host, node_id)
    values 
    (:host, :root)

    </querytext>
</fullquery>

<fullquery name="node_list">      
      <querytext>
          select node_id from site_nodes
      </querytext>
</fullquery>

</queryset>