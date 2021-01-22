<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="acs_admin_url_get">      
      <querytext>

    select site_node__url(node_id) as acs_admin_url, instance_name
    from site_nodes s, apm_packages p
    where s.object_id = p.package_id
    and p.package_key = 'acs-admin'
    limit 1

      </querytext>
</fullquery>

 
</queryset>
