<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="ad_context_bar.context">
<querytext>
    select site_node__url(node_id) as url, object_id,
           acs_object__name(object_id) as object_name,
           tree_level(tree_sortkey) as level
    from site_nodes
    where tree_sortkey like (select tree_sortkey from site_nodes where
node_id = :node_id) || '%'
    order by level desc
</querytext>
</fullquery>

</queryset>
