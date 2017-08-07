<?xml version="1.0"?>
<queryset>

<fullquery name="ad_acs_admin_node.acs_admin_node_p">      
      <querytext>
      
        select case when count(object_id) = 0 then 0 else 1 end
        from site_nodes
        where object_id = (select package_id 
                           from apm_packages 
                           where package_key = 'acs-admin')
    
      </querytext>
</fullquery>

</queryset>
