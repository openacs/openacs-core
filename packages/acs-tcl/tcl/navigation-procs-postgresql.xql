<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>                                                    
<fullquery name="ad_context_bar.context">      
      <querytext>
      
    select site_node__url(node_id) as url, object_id,
           acs_object__name(object_id) as object_name,
           tree_level(n2.tree_sortkey) as level
    from site_nodes n1, site_nodes n2
    where n1.tree_sortkey = (select tree_sortkey
                              from site_nodes
                             where node_id = :node_id)
      and n2.tree_sortkey <= n1.tree_sortkey
      and n1.tree_sortkey like (n2.tree_sortkey || '%')
 order by level desc
  
      </querytext>
</fullquery>

 
</queryset>
