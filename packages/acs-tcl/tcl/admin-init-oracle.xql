<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="path_select">      
      <querytext>
      
	select package_id, site_node.url(node_id) as url from apm_packages p, site_nodes n
	where p.package_id = n.object_id
    
      </querytext>
</fullquery>

 
</queryset>
