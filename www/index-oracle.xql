<?xml version="1.0"?>
<queryset>
    <rdbms>
      <type>oracle</type>
      <version>8.1.6</version>
    </rdbms>

  <fullquery name="site_nodes">
    <querytext>
  select site_node.url(node_id) as url, acs_object.name(object_id) as name
      from site_nodes
      where parent_id = site_node.node_id('/')
      and object_id is not null
      and acs_permission.permission_p(
          object_id, 
          nvl(:user_id, acs.magic_object_id('the_public')), 
          'read') = 't'
        order by upper(name)
    </querytext>
  </fullquery>

</queryset>
