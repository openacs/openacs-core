<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_node_url">      
      <querytext>
      
	select site_node.url(s.node_id) as return_url
	  from site_nodes s, apm_packages p
	 where s.object_id = p.package_id
	   and s.node_id = :node_id
    
      </querytext>
</fullquery>

 
</queryset>
