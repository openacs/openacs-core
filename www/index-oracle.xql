<?xml version="1.0"?>
<queryset>
    <rdbms>
      <type>oracle</type>
      <version>8.1.6</version>
    </rdbms>

  <fullquery name="site_nodes">
    <querytext>
  select site_node.url(node_id) as url, acs_object.name(object_id) as name,
         apm_package_types.initial_install_p
      from site_nodes, apm_packages, apm_package_types
      where parent_id = site_node.node_id('/')
      and object_id is not null
      and acs_permission.permission_p(
          object_id, 
          nvl(:user_id, acs.magic_object_id('the_public')), 
          'read') = 't'
      and apm_packages.package_id = site_nodes.object_id
      and apm_package_types.package_key = apm_packages.package_key
    order by initial_install_p, upper(name), name
    </querytext>
  </fullquery>

</queryset>
