<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>                                                    
<fullquery name="ad_context_bar.context">      
      <querytext>
      
    select site_node.url(node_id) as url, object_id,
           acs_object.name(object_id) as object_name,
           level
    from site_nodes
    start with node_id = :node_id
    connect by prior parent_id = node_id
    order by level asc
  
      </querytext>
</fullquery>

 
</queryset>
