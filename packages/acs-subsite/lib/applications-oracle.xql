<?xml version="1.0"?>
<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

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
    and    exists (select 1 
                   from   acs_object_party_privilege_map perm 
                   where  perm.object_id = p.package_id
                   and    perm.privilege = 'read'
                   and    perm.party_id = :user_id)    
    order  by upper(instance_name)      

      </querytext>
  </fullquery>
</queryset>

