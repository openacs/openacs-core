<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="site_node::delete.delete_site_node">
        <querytext>
            select site_node__delete(:node_id);
        </querytext>
    </fullquery>

    <fullquery name="site_node::update_cache.select_child_site_nodes">
        <querytext>
	  with recursive site_node_tree AS (
	     select node_id, parent_id, name, directory_p, pattern_p, object_id
	     from site_nodes where node_id = :node_id
	  union all
	     select c.node_id, c.parent_id, c.name, c.directory_p, c.pattern_p, c.object_id
	     from site_node_tree tree, site_nodes c
	     where  c.parent_id = tree.node_id
	  )
	  select
	     t.node_id, t.parent_id, t.name, t.directory_p, t.pattern_p, t.object_id,
	     p.package_key, p.package_id, p.instance_name, pt.package_type
	  from   site_node_tree t, apm_packages p, apm_package_types pt
	  where  pt.package_key = p.package_key
	  and    t.object_id = p.package_id
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
            from site_nodes n left join 
                 apm_packages p on n.object_id = p.package_id left join
                 apm_package_types t using (package_key)
            where n.node_id = :node_id
        </querytext>
    </fullquery>

</queryset>
