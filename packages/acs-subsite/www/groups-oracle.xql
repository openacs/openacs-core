<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_subsites">      
      <querytext>
      
    select n.node_id, 
           n.name, 
           p.package_id,
           p.instance_name,
           acs_permission.permission_p(p.package_id, :user_id, 'read') as read_p
    from   site_nodes n,
           apm_packages p
    where  n.parent_id = :subsite_node_id
    and    p.package_id = n.object_id
    and    p.package_key = 'acs-subsite'


      </querytext>
</fullquery>
 
</queryset>
