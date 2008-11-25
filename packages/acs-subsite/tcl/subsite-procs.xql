<?xml version="1.0"?>
<queryset>

<fullquery name="subsite::default::create_app_group.group_exists">      
      <querytext>
      
	    select 1
            from dual
            where exists (select 1
                          from application_groups
                          where package_id = :package_id)
	
      </querytext>
</fullquery>

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

    <fullquery name="subsite::package_keys.get_keys">
        <querytext>

        select package_key from apm_package_versions where subsite_p = 't' and enabled_p = 't'

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
        (key, name, template, css, form_template, list_template, list_filter_template)
      values
        (:key, :name, :template, :css, :form_template, :list_template, :list_filter_template)
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

<fullquery name="subsite::util::get_package_descendent_options.get">      
  <querytext>
    select pretty_name, package_key
    from apm_package_types
    where implements_subsite_p = 't'
      and package_key in ($in_clause)
    order by pretty_name
  </querytext>
</fullquery>  

<fullquery name="subsite::util::convert_type.update_package_key">      
  <querytext>
    update apm_packages
    set package_key = :new_package_key
    where package_id = :subsite_id
  </querytext>
</fullquery>  

<fullquery name="subsite::util::convert_type.get_params">      
  <querytext>
    select parameter_name, parameter_id
    from apm_parameters
    where package_key = :old_package_key
  </querytext>
</fullquery>  

<fullquery name="subsite::util::convert_type.get_new_parameter_id">      
  <querytext>
    select parameter_id as new_parameter_id
    from apm_parameters
    where package_key = :new_package_key
      and parameter_name = :parameter_name
  </querytext>
</fullquery>  

<fullquery name="subsite::util::convert_type.update_param">      
  <querytext>
    update apm_parameter_values
    set parameter_id = :new_parameter_id
    where parameter_id = :parameter_id
      and package_id = :subsite_id
  </querytext>
</fullquery>  

</queryset>
