<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>


<fullquery name="root_id">
      <querytext>
      
      select site_node__node_id('/', null)
      
      </querytext>
</fullquery>


<fullquery name="host_node_pair">      
      <querytext>

    select host, node_id, site_node__url(node_id) as url 
    from host_node_map
      
      </querytext>
</fullquery>
 
</queryset>
