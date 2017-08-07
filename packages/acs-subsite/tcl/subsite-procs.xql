<?xml version="1.0"?>
<queryset>

<fullquery name="subsite::default::create_app_group.subsite_name_query">      
      <querytext>
      
	    select instance_name
	    from apm_packages
	    where package_id = :package_id
	
      </querytext>
</fullquery>

 
<fullquery name="subsite::default::create_app_group.parent_subsite_query">      
      <querytext>
      
         select m.group_id as supersite_group_id, p.instance_name as supersite_name
         from application_groups m, apm_packages p, site_nodes s1, site_nodes s2
         where s1.node_id = :node_id
           and s2.node_id = s1.parent_id
           and p.package_id = s2.object_id
	   and m.package_id = :subsite_id

      </querytext>
</fullquery>

 
<fullquery name="subsite::instance_name_exists_p.select_name_exists_p">      
      <querytext>
      
	select count(*) 
	  from site_nodes
	 where parent_id = :node_id
	   and name = :instance_name
    
      </querytext>
</fullquery>
 
<fullquery name="subsite::util::object_type_pretty_name.select_pretty_name">      
      <querytext>
      
	select pretty_name from acs_object_types 
	where object_type = :object_type
    
      </querytext>
</fullquery>

    <fullquery name="subsite::get_url.get_vhost">
        <querytext>

    select host
      from host_node_map
     where node_id = :node_id
     $where_clause

        </querytext>
    </fullquery>
 
    <partialquery name="subsite::get_url.strict_search">
        <querytext>
        and host = :search_vhost
        </querytext>
    </partialquery>

  <fullquery name="subsite::get_theme_options.get_subsite_themes">
    <querytext>
      select name, key
      from subsite_themes
    </querytext>
  </fullquery>
  
  <fullquery name="subsite::new_subsite_theme.insert_subsite_theme">
    <querytext>
      insert into subsite_themes
        (key, name, template, css, js, form_template, list_template,
	list_filter_template, dimensional_template, resource_dir,
	streaming_head, local_p)
      values
        (:key, :name, :template, :css, :js, :form_template, :list_template,
	:list_filter_template, :dimensional_template, :resource_dir,
	:streaming_head, :local_p)
    </querytext>
  </fullquery>
  
  <fullquery name="subsite::delete_subsite_theme.delete_subsite_theme">
    <querytext>
      delete from subsite_themes
      where key = :key
    </querytext>
  </fullquery>

  <fullquery name="subsite::set_theme.get_theme_paths">
    <querytext>
      select *
      from subsite_themes
      where key = :theme
    </querytext>
  </fullquery>
 
<fullquery name="subsite::util::get_package_options.get">      
  <querytext>
    select pretty_name, package_key
    from apm_package_types
    where implements_subsite_p = 't'
    order by pretty_name
  </querytext>
</fullquery>

</queryset>
