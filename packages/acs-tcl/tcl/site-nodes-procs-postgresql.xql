<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="site_nodes_sync_helper.nodes_select">
<querytext>
    select site_node__url(n.node_id) as url, n.node_id, n.directory_p,
           n.pattern_p, n.object_id, o.object_type, n.package_key, n.package_id
    from acs_objects o left outer join (select n.node_id, n.directory_p, n.pattern_p, n.object_id, p.package_key, p.package_id
                           from site_nodes n, apm_packages p
                          where n.object_id = p.package_id) n
    on n.object_id = o.object_id
</querytext>
</fullquery>

</queryset>
