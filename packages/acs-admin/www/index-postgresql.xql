<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="subsite_admin_urls">      
      <querytext>
      
    select site_node__url(node_id) || 'admin/' as admin_url, instance_name
    from site_nodes s, apm_packages p
    where s.object_id = p.package_id
    and p.package_key = 'acs-subsite'

      </querytext>
</fullquery>

 
</queryset>
