<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>
 
<fullquery name="site_node_create">
<querytext>
select site_node__new (
        :new_node_id,
        :parent_id,
        :name,
	NULL,
        :directory_p,
        :pattern_p,
        :user_id,
        :ip_address
        )
</querytext>
</fullquery>

<fullquery name="site_node_mount_application.create_node">      
      <querytext>

	  select site_node__new (
                    null,
                    :parent_node_id,
                    :instance_name,
                    null,
                    't',
                    't',
                    null,
                    null
	  );
    
      </querytext>
</fullquery>

<fullquery name="site_node_closest_ancestor_package_url.select_url">      
      <querytext>
      
	select site_node__url(node_id) from site_nodes where object_id=:subsite_pkg_id
    
      </querytext>
</fullquery>
 
<fullquery name="site_map_unmount_application.node_delete">      
      <querytext>
      
	    select site_node__delete(:node_id);
	
      </querytext>
</fullquery>

 
</queryset>
