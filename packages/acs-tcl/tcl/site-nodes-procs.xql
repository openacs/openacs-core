<?xml version="1.0"?>
<queryset>

<fullquery name="site_nodes_sync_helper.nodes_select">      
      <querytext>

    select site_node__url(n.node_id) as url, n.node_id, n.directory_p,
           n.pattern_p, n.object_id, o.object_type, n.package_key, n.package_id
    from acs_objects o left outer join
        (select n.node_id, n.directory_p, n.pattern_p, n.object_id, 
                p.package_key, p.package_id
           from site_nodes n, apm_packages p
          where n.object_id = p.package_id) n
         using (object_id)
  
      </querytext>
</fullquery>


<fullquery name="site_node_create_package_instance.update_site_nodes">      
      <querytext>
      
	update site_nodes
	   set object_id = :package_id
	 where node_id = :node_id
    
      </querytext>
</fullquery>

 
<fullquery name="site_node_mount_application.get_context">      
      <querytext>
      
        select object_id as context_id
          from site_nodes 
         where node_id = :parent_node_id
    
      </querytext>
</fullquery>

 
<fullquery name="site_map_unmount_application.unmount">      
      <querytext>
      
	update site_nodes
	   set object_id = null
	 where node_id = :node_id
    
      </querytext>
</fullquery>

</queryset>
