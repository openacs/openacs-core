<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="site_node::delete.delete_site_node">
        <querytext>
            begin site_node.del(:node_id); end;
        </querytext>
    </fullquery>

    <fullquery name="site_node::update_cache.select_child_site_nodes">
        <querytext>
	    select n.node_id,
		   n.parent_id,
		   n.name,
		   n.directory_p,
		   n.pattern_p,
		   n.object_id,
		   p.package_key,
		   p.package_id,
		   p.instance_name,
		   t.package_type
	    from apm_packages p,
		 apm_package_types t,
		 (select node_id, parent_id, name, directory_p, pattern_p, object_id, 
		         rownum as nodes_rownum
		  from site_nodes
		  connect by parent_id = prior node_id
		  start with node_id = :node_id) n
	    where n.object_id = p.package_id(+)
	    and t.package_key (+) = p.package_key
	    order by n.nodes_rownum
        </querytext>
    </fullquery>

    <fullquery name="site_node::update_cache.select_site_node">
        <querytext>
	    select n.node_id,
		   n.parent_id,
		   n.name,
		   n.directory_p,
		   n.pattern_p,
		   n.object_id,
		   p.package_key,
		   p.package_id,
		   p.instance_name,
		   t.package_type
	    from apm_packages p, apm_package_types t, site_nodes n
	    where n.node_id = :node_id
	    and n.object_id = p.package_id(+)
	    and t.package_key (+) = p.package_key
        </querytext>
    </fullquery>

</queryset>
