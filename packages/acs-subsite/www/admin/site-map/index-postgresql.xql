<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="path_select">      
      <querytext>
      
  select node_id, name, directory_p, tree_level(tree_sortkey) as level,
         acs_object__name(object_id) as obj_name,
         acs_permission__permission_p(object_id, :user_id, 'admin') as admin_p
  from site_nodes
  where tree_sortkey like (select tree_sortkey from site_nodes where node_id = :root_id) || '%'
  order by level desc

      </querytext>
</fullquery>

 
<fullquery name="node_id">      
      <querytext>
      select site_node__node_id('/', null) 
      </querytext>
</fullquery>

 
<fullquery name="nodes_select">      
      <querytext>
select package_id,
       package_key,
       apm_package_type__num_parameters(package_key) as parameter_count,
       node_id, url, parent_url, name, root_p, mylevel - 1 as mylevel, object_id,
       object_name, directory_p, parent_id, n_children,
       (select case when acs_permission__permission_p(object_id, :user_id, 'admin') = 't' then 1 else 0 end) as object_admin_p
from apm_packages p right outer join (
  select node_id, site_node__url(node_id) as url,
         site_node__url(parent_id) as parent_url,
         name,
         (select count(*)
          from site_nodes
          where parent_id = n.node_id) as n_children,
         case when node_id = site_node__node_id('/', null) then 1 else 0 end as root_p,
         tree_level(tree_sortkey) as mylevel,
	 tree_sortkey,
         object_id,
         acs_object__name(object_id) as object_name,
         directory_p,
         parent_id
  from site_nodes n
  where (object_id is null or
         acs_permission__permission_p(object_id, :user_id, 'read') = 't') and
	tree_sortkey like (select tree_sortkey from site_nodes where node_id = coalesce(:root_id, site_node__node_id('/', null))) || '%' and
	(parent_id is null or parent_id in ([join $expand ", "]))) site_map
 on site_map.object_id = p.package_id
 order by site_map.tree_sortkey

      </querytext>
</fullquery>

 
<fullquery name="package_types">      
      <querytext>
      
	select package_key, pretty_name
	from apm_package_types
	where not (apm_package__singleton_p(package_key) = 1 and
	      apm_package__num_instances(package_key) >= 1)
	order by pretty_name
      
      </querytext>
</fullquery>

 
<fullquery name="services_select">      
      <querytext>
      
  select package_id, ap.package_key, acs_object__name(package_id) as instance_name,
  apm_package_type__num_parameters(ap.package_key) as parameter_count
  from apm_packages ap, apm_package_types
  where ap.package_key = apm_package_types.package_key
  and package_type = 'apm_service'
  and (acs_permission__permission_p(package_id, :user_id, 'read') = 't' or
       acs_permission__permission_p(package_id, acs__magic_object_id('the_public'), 'read') = 't')

      </querytext>
</fullquery>

 
</queryset>
