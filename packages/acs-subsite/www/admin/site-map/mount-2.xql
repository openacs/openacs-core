<?xml version="1.0"?>
<queryset>

<fullquery name="mount">      
      <querytext>
      
    update site_nodes
    set object_id = :package_id
    where node_id = :node_id
    and object_id is null
  
      </querytext>
</fullquery>

 
</queryset>
