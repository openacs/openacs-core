<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="nodes_select">
        <querytext>
            select package_id,
                   package_key,
                   (select pretty_name from apm_package_types where package_key = p.package_key) as package_pretty_name,
                   apm_package_type.num_parameters(package_key) parameter_count,
                   node_id,
                   url,
                   parent_url,
                   name,
                   root_p,
                   mylevel - 1 as mylevel,
                   object_id,
                   object_name,
                   directory_p,
                   parent_id,
                   n_children,
                   decode(acs_permission.permission_p(object_id, :user_id, 'admin'), 't', 1, 0) object_admin_p,
                   (select view_p from site_nodes_selection where node_id=site_map.node_id) as view_p
            from apm_packages p,
                 (select node_id,
                         site_node.url(node_id) as url,
                         site_node.url(parent_id) as parent_url,
                         name,
                         (select count(*)
                          from site_nodes
                          where parent_id = n.node_id) as n_children,
                         decode(node_id, site_node.node_id('/'), 1, 0) as root_p,
                         level as mylevel,
                         object_id,
                         acs_object.name(object_id) as object_name,
                         directory_p,
                         parent_id
                  from site_nodes n
                  where (object_id is null
                         or exists (
                            select 1 from acs_object_party_privilege_map ppm 
                             where ppm.object_id = n.object_id 
                               and ppm.party_id = :user_id 
                               and ppm.privilege = 'read'))
            start with node_id = nvl(:root_id, site_node.node_id('/'))
            connect by prior node_id = parent_id and parent_id in ([join $expand ", "])) site_map
            where site_map.object_id = p.package_id (+)
            order by url
        </querytext>
    </fullquery>

    <fullquery name="path_select">
        <querytext>
    WITH site_node_path(node_id,parent_id,name,object_id,directory_p,mylevel) AS (
       select node_id, parent_id, name, object_id, directory_p, 1 as mylevel
       from site_nodes where node_id = :root_id
    UNION ALL
       select c.node_id, c.parent_id, c.name, c.object_id, c.directory_p, p.mylevel+1 mylevel
       from site_node_path p, site_nodes c where  c.node_id = p.parent_id
    )
    select
       node_id, name, directory_p, mylevel,
       acs_object.name(object_id) as obj_name,
       acs_permission.permission_p(object_id, :user_id, 'admin') as admin_p
    from   site_node_path order by mylevel desc
        </querytext>
    </fullquery>

</queryset>
