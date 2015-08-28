<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_applications">      
      <querytext>

    select n.node_id
    from   site_nodes n,
           site_nodes np,
           apm_packages p
    where  np.node_id = :subsite_node_id
    and    n.tree_sortkey between np.tree_sortkey and tree_right(np.tree_sortkey)
    and    p.package_id = n.object_id
    order  by n.tree_sortkey

      </querytext>
</fullquery>

<fullquery name="select_applications_page">      
      <querytext>

    select n.node_id, 
           n.name, 
           p.package_id,
           p.instance_name,
           tree_level(n.tree_sortkey) - tree_level(np.tree_sortkey) as treelevel,
           pt.pretty_name as package_pretty_name,
           (select count(*) from apm_parameters par where par.package_key = pt.package_key) as num_parameters
    from   site_nodes n,
           site_nodes np,
           apm_packages p,
           apm_package_types pt
    where  np.node_id = :subsite_node_id
    and    n.tree_sortkey between np.tree_sortkey and tree_right(np.tree_sortkey)
    and    p.package_id = n.object_id
    and    pt.package_key = p.package_key
    and [template::list::page_where_clause -name applications -key n.node_id]
    [template::list::filter_where_clauses -and -name applications]
    order  by n.tree_sortkey

      </querytext>
</fullquery>

 
</queryset>
