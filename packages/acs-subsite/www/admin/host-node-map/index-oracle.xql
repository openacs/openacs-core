<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="root_id">
      <querytext>
      
      select site_node.node_id('/') from dual
      
      </querytext>
</fullquery>


<fullquery name="host_node_pair">      
      <querytext>

    select host, node_id, site_node.url(node_id) as url 
    from host_node_map
      
      </querytext>
</fullquery>
 
</queryset>
