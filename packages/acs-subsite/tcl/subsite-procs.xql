<?xml version="1.0"?>
<queryset>

<fullquery name="acs_subsite_post_instantiation.subsite_name_query">      
      <querytext>
      
	    select instance_name
	    from apm_packages
	    where package_id = :package_id
	
      </querytext>
</fullquery>

 
<fullquery name="acs_subsite_post_instantiation.parent_subsite_query">      
      <querytext>
      
		select m.group_id as supersite_group_id,
                       p.instance_name as supersite_name
		from application_group_element_map m,
                     apm_packages p
		where p.package_id = m.package_id
                  and container_id = group_id
                  and element_id = :subsite_group_id
                  and rel_type = 'composition_rel'
	    
      </querytext>
</fullquery>

 
<fullquery name="acs_subsite_post_instantiation.select_name_exists_p">      
      <querytext>
      
	select count(*) 
	  from site_nodes
	 where parent_id = :node_id
	   and name = :instance_name
    
      </querytext>
</fullquery>

 
<fullquery name="acs_subsite_post_instantiation.select_pretty_name">      
      <querytext>
      
	select pretty_name from acs_object_types 
	where object_type = :object_type
    
      </querytext>
</fullquery>

 
</queryset>
