<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_applications">      
      <querytext>

    select n.node_id
    from   site_nodes n,
           apm_packages p
    	   left join lang_messages m
	     on m.locale = :locale and
	        '#' || m.package_key || '.' || m.message_key || '#' = p.instance_name
           left join lang_messages md
	     on m.locale = 'en_US' and
  	        '#' || md.package_key || '.' || md.message_key || '#' = p.instance_name,
           apm_package_types pt
    where  n.parent_id = :subsite_node_id
    and    p.package_id = n.object_id
    and    pt.package_key = p.package_key
    and [template::list::filter_where_clauses -and -name applications]
    order  by lower(p.instance_name)

      </querytext>
</fullquery>

<fullquery name="select_applications_page">      
      <querytext>

    select n.node_id, 
           n.name, 
           p.package_id,
           p.instance_name,
           pt.pretty_name as package_pretty_name,
           0 as treelevel,
           (select count(*) from apm_parameters par where par.package_key = pt.package_key) as parameters_p
    from   site_nodes n,
           apm_packages p,
           apm_package_types pt
    where  n.parent_id = :subsite_node_id
    and    p.package_id = n.object_id
    and    pt.package_key = p.package_key
    and [template::list::page_where_clause -name applications -key n.node_id]
    
    order  by lower(p.instance_name)
      </querytext>
</fullquery>
 
</queryset>
