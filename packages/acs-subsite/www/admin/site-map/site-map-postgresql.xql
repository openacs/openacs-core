<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="nodes_select">
        <rdbms><type>postgresql</type><version>8.4</version></rdbms>
        <querytext>
            select package_id,
                   package_key,
                   pretty_name as package_pretty_name,
                   apm_package_type__num_parameters(package_key) as parameter_count,
                   node_id, url, parent_url, name, root_p, mylevel, object_id,
                   directory_p, parent_id, n_children,
                   p.instance_name as object_name,
                   acs_permission__permission_p(object_id, :user_id, 'admin') as object_admin_p,
                   (select view_p from site_nodes_selection where node_id=site_map.node_id) as view_p
            from apm_packages p join apm_package_types using (package_key) right outer join
                (WITH RECURSIVE site_node_path AS (
	          select node_id, parent_id
	          from site_nodes where node_id = :root_id
	        UNION ALL
	          select c.node_id, c.parent_id
	          from site_node_path p, site_nodes as c where  c.node_id = p.parent_id
	       )
	       select sm0.*, (char_length(url)-char_length(replace(url, '/', ''))-1) as mylevel
	       from (select distinct n.node_id,
                         site_node__url(n.node_id) as url,
                         site_node__url(n.parent_id) as parent_url,
                         n.name,
                         case when exists (select 1 from site_nodes where parent_id = n.node_id) then 1 else 0 end as n_children,
                         case when n.parent_id is NULL then 1 else 0 end as root_p,
                         n.object_id,
                         n.directory_p,
                         n.parent_id
                  from site_nodes n, site_node_path path
                  where (n.object_id is null or acs_permission__permission_p(n.object_id, :user_id, 'read'))
                  and (n.node_id = path.node_id or n.parent_id in ([join $expand ", "]))) sm0) as site_map
            on site_map.object_id = p.package_id
            order by url
        </querytext>
    </fullquery>

</queryset>
