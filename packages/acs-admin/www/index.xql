<?xml version="1.0"?>
<queryset>

<fullquery name="subsite_admin_urls">      
      <querytext>
      
    select site_node.url(node_id) || 'admin/' subsite_admin_url, instance_name
    from site_nodes s, apm_packages p
    where s.object_id = p.package_id
    and p.package_key = 'acs-subsite'

      </querytext>
</fullquery>

 
</queryset>
