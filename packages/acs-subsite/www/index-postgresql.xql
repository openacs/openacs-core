<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="name">      
      <querytext>
      
    select acs_object__name(:package_id) 

      </querytext>
</fullquery>

 
<fullquery name="site_nodes">      
      <querytext>

  select site_node__url(n.node_id) as url, acs_object__name(n.object_id) as name
    from site_nodes n
   where n.parent_id = :node_id
    and n.object_id is not null
    and acs_permission__permission_p(n.object_id, :user_id, 'read') = 't'
   order by name

      </querytext>
</fullquery>

 
</queryset>
