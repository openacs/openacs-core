<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="subsite_admin_urls">      
      <querytext>
      
    select s.node_id,
           site_node.url(node_id) as node_url,
           instance_name
    from   site_nodes s, apm_packages p, apm_package_types t
    where  s.object_id = p.package_id
    and    p.package_key = t.package_key
    and    t.implements_subsite_p = 't'

      </querytext>
</fullquery>

 
</queryset>
