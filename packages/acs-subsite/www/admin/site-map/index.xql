<?xml version="1.0"?>
<queryset>

<fullquery name="root_node">      
      <querytext>
      
  select parent_id, object_id
  from site_nodes
  where node_id = :root_id

      </querytext>
</fullquery>

 
</queryset>
