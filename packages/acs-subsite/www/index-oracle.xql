<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="name">      
      <querytext>
      
    select acs_object.name(:package_id) from dual

      </querytext>
</fullquery>

 
<fullquery name="site_nodes">      
      <querytext>
      
  select site_node.url(n.node_id) as url, acs_object.name(n.object_id) as name
    from site_nodes n
   where n.parent_id = :node_id
    and n.object_id is not null
    and acs_permission.permission_p(n.object_id, :user_id, 'read') = 't'
   order by name

      </querytext>
</fullquery>

 
</queryset>
