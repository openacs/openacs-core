<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="site_nodes">      
      <querytext>

  select site_node__url(n.node_id) as url, acs_object__name(n.object_id) as name
    from site_nodes n, apm_packages p, apm_package_types t
   where n.parent_id = :node_id
    and acs_permission__permission_p(n.object_id, :user_id, 'read') = 't'
    and p.package_id = n.object_id
    and t.package_key = p.package_key
    and t.package_type = 'apm_service'
    and t.package_key != 'acs-subsite'        
   order by name

      </querytext>
</fullquery>

 
</queryset>
