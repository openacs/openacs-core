<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="site_node_create">
<querytext>
        begin
        :1 := site_node.new (
        node_id => :new_node_id,
        parent_id => :parent_id,
        name => :name,
        directory_p => :directory_p,
        pattern_p => :pattern_p,
        creation_user => :user_id,
        creation_ip => :ip_address
        );
        end;
</querytext>
</fullquery>

<fullquery name="site_nodes_sync_helper.nodes_select">      
      <querytext>
      
    select site_node.url(n.node_id) as url, n.node_id, n.directory_p,
           n.pattern_p, n.object_id, o.object_type, n.package_key, n.package_id
    from acs_objects o, (select n.node_id, n.directory_p, n.pattern_p, n.object_id, p.package_key, p.package_id
                           from site_nodes n, apm_packages p
                          where n.object_id = p.package_id) n
    where n.object_id = o.object_id (+)
  
      </querytext>
</fullquery>

 
<fullquery name="site_node_mount_application.create_node">      
      <querytext>
      
	begin
	  :1 := site_node.new (
                    parent_id => :parent_node_id,
                    name => :instance_name,
                    directory_p => 't',
                    pattern_p => 't'
	  );
	end;
    
      </querytext>
</fullquery>

<fullquery name="site_node_closest_ancestor_package_url.select_url">      
      <querytext>
      
	select site_node.url(node_id) from site_nodes where object_id=:subsite_pkg_id
    
      </querytext>
</fullquery>

 <fullquery name="site_map_unmount_application.node_delete">      
      <querytext>
      
	    begin site_node.delete(:node_id); end;
	
      </querytext>
</fullquery>

</queryset>
