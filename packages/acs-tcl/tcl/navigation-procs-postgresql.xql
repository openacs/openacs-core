<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>                                                    
<fullquery name="ad_context_bar.context">      
      <querytext>
      
    select site_node__url(n2.node_id) as url, n2.object_id,
           acs_object__name(n2.object_id) as object_name,
           tree_level(n2.tree_sortkey) as level
    from (select tree_ancestor_keys(site_node_get_tree_sortkey(:node_id)) as tree_sortkey) parents,
        site_nodes n2
    where n2.tree_sortkey = parents.tree_sortkey
 order by level asc
  
      </querytext>
</fullquery>

 
</queryset>
