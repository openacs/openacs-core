<?xml version="1.0"?>
<queryset>
    <rdbms>
      <type>postgresql</type>
      <version>7.1</version>
    </rdbms>

  <fullquery name="site_nodes">
    <querytext>
  select site_node__url(node_id) as url, acs_object__name(object_id) as name
      from site_nodes
      where parent_id = site_node__node_id('/',NULL)
      and object_id is not null
      and acs_permission__permission_p(
          object_id, 
          coalesce(:user_id, acs__magic_object_id('the_public')), 
          'read') = 't'
        order by upper(acs_object__name(object_id))
    </querytext>
  </fullquery>

</queryset>
