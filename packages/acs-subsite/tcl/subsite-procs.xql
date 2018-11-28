<?xml version="1.0"?>
<queryset>

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
