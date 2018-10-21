<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_applications">      
      <querytext>
    select node_id from (
       WITH RECURSIVE site_node_tree AS (
         select node_id, parent_id, name, object_id from site_nodes where node_id = :subsite_node_id
       UNION ALL
         select c.node_id, c.parent_id, c.name, c.object_id from site_node_tree tree, site_nodes as c
         where  c.parent_id = tree.node_id
       )
       select n.node_id, n.parent_id, n.name, site_node__url(n.node_id) as url
       from   site_node_tree n, apm_packages p
	      left outer join lang_messages m
	        on m.locale = 'en_US' and
  	           '#' || m.package_key || '.' || m.message_key || '#' = p.instance_name
              left outer join lang_messages md
	        on m.locale = 'en_US' and
  	           '#' || md.package_key || '.' || md.message_key || '#' = p.instance_name,
	      apm_package_types pt
       where  p.package_id = n.object_id
       and    pt.package_key = p.package_key
       [template::list::filter_where_clauses -and -name applications]
       order  by url) node_tree
      </querytext>
</fullquery>

<fullquery name="select_applications_page">      
      <querytext>
    select
       node_id, name, package_id, instance_name, package_pretty_name, parameters_p,
       (char_length(url)-char_length(replace(url, '/', ''))-1) as treelevel
    from (
       select n.node_id, 
              n.name, 
              p.package_id,
              p.instance_name,
              site_node__url(n.node_id) as url,
              pt.pretty_name as package_pretty_name,
              exists (select 1 from apm_parameters where package_key = pt.package_key) as parameters_p
       from   site_nodes n, apm_packages p, apm_package_types pt
       where  p.package_id = n.object_id
       and    pt.package_key = p.package_key
       and    [template::list::page_where_clause -name applications -key n.node_id]
    ) sm0 order by url
      </querytext>
</fullquery>

 
</queryset>
