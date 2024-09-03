<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="nodes_select">
        <rdbms><type>postgresql</type><version>8.4</version></rdbms>
        <querytext>
            select p.package_id,
                   p.package_key,
                   (select pretty_name from apm_package_types
                     where package_key = p.package_key) as package_pretty_name,
                   case when exists (select 1 from apm_parameters
                     where package_key = p.package_key) then 1 else 0 end as parameter_count,
                   n.node_id,
                   n.parent_id,
                   case when exists (select 1 from site_nodes
                     where parent_id = n.node_id) then 1 else 0 end as n_children,
                   n.parent_id is null as root_p,
                   n.name,
                   site_node__url(n.node_id) as url,
                   length(site_node__url(n.node_id)) -
                    length(replace(site_node__url(n.node_id), '/', '')) -
                    1 as mylevel,
                   n.object_id,
                   n.directory_p,
                   p.instance_name as object_name,
                   acs_permission.permission_p(object_id, :user_id, 'admin') as object_admin_p,
                   s.view_p
             from site_nodes n
                  left outer join apm_packages p on n.object_id = p.package_id,
                  site_nodes_selection s
            where n.node_id = s.node_id
              and (n.object_id is null or acs_permission.permission_p(n.object_id, :user_id,'read'))
              and (n.parent_id is null or n.parent_id in ([join $expand ", "]))
            order by url
        </querytext>
    </fullquery>

</queryset>
