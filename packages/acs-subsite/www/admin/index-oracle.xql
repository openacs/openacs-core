<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="acs_admin_url_get">      
      <querytext>
      
    select site_node.url(node_id) acs_admin_url, instance_name
    from site_nodes s, apm_packages p
    where s.object_id = p.package_id
    and p.package_key = 'acs-admin'
    and rownum = 1

      </querytext>
</fullquery>

 
</queryset>
