<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="subsite_admin_urls">      
      <querytext>
      
    select s.node_id,
           site_node__url(node_id) as node_url,
           instance_name,
	   p.package_id
    from   site_nodes s, apm_packages p
    where  s.object_id = p.package_id
    and    p.package_key in ($package_keys)

      </querytext>
</fullquery>

 
</queryset>
