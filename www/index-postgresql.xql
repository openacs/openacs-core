<?xml version="1.0"?>
<queryset>
    <rdbms>
      <type>postgresql</type>
      <version>7.1</version>
    </rdbms>

  <fullquery name="site_nodes">
    <querytext>
  select site_node__url(node_id) as url, acs_object__name(object_id) as name,
         apm_package_types.initial_install_p  
      from site_nodes, apm_packages, apm_package_types
      where parent_id = site_node__node_id('/',NULL)
      and object_id is not null
      and acs_permission__permission_p(
          object_id, 
          coalesce(:user_id, acs__magic_object_id('the_public')), 
          'read') = 't'
      and apm_packages.package_id = site_nodes.object_id
      and apm_package_types.package_key = apm_packages.package_key
    order by initial_install_p, name
    </querytext>
  </fullquery>

</queryset>
