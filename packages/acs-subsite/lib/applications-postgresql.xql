<?xml version="1.0"?>
<queryset>
  <rdbms><type>postgresql</type><version>9.0</version></rdbms>

  <fullquery name="select_applications">
    <querytext>

    select p.package_id,
           p.instance_name,
           n.node_id, 
           n.name
    from   site_nodes n,
           apm_packages p,
           apm_package_types t
    where  n.parent_id = :subsite_node_id
    and    p.package_id = n.object_id
    and    t.package_key = p.package_key
    and    t.package_type = 'apm_application'
    and    acs_permission__permission_p(p.package_id, :user_id, 'read')
    order  by upper(instance_name)      

      </querytext>
  </fullquery>
</queryset>

