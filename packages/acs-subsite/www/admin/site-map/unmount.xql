<?xml version="1.0"?>
<queryset>

<fullquery name="unmount">      
      <querytext>
      
    update site_nodes
    set object_id = null
    where node_id = :node_id
  
      </querytext>
</fullquery>

 
</queryset>
