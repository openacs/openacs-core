<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="application_group::contains_party_p.app_group_contains_party_p">      
      <querytext>
      
	    select case when exists (
	        select 1
	        from application_group_element_map
	        where package_id = :package_id
	          and element_id = :party_id
	      union all
	        select 1
	        from application_groups
	        where package_id = :package_id
	          and group_id = :party_id
	    ) then 1 else 0 end
            from dual
	
      </querytext>
</fullquery>

 
<fullquery name="application_group::contains_party_p.app_group_contains_party_p">      
      <querytext>
      
	    select case when exists (
	        select 1
	        from application_group_element_map
	        where package_id = :package_id
	          and element_id = :party_id
	      union all
	        select 1
	        from application_groups
	        where package_id = :package_id
	          and group_id = :party_id
	    ) then 1 else 0 end
            from dual
	
      </querytext>
</fullquery>

 
<fullquery name="application_group::contains_relation_p.app_group_contains_rel_p">      
      <querytext>
      
	    select case when exists (
	        select 1
	        from application_group_element_map
	        where package_id = :package_id
	          and rel_id = :rel_id
	    ) then 1 else 0 end
            from dual
	
      </querytext>
</fullquery>

 
<fullquery name="application_group::contains_segment_p.app_group_contains_segment_p">      
      <querytext>
      
	    select case when exists (
	        select 1
	        from application_group_segments
	        where package_id = :package_id
	          and segment_id = :segment_id
	    ) then 1 else 0 end
            from dual
	
      </querytext>
</fullquery>

 
<fullquery name="application_group::group_id_from_package_id.application_group_from_package_id_query">      
      <querytext>
      
	    begin
	    :1 := application_group.group_id_from_package_id (
	        package_id => :package_id,
	        no_complain_p => :no_complain_p
	    );
	    end;
	
      </querytext>
</fullquery>

 
<fullquery name="application_group::new.parent_group_id_query">      
      <querytext>
      
		    select ag.group_id as parent_group_id
		    from application_groups ag,
		         apm_packages,
		         (select object_id, rownum as tree_rownum
		          from site_nodes
		          start with node_id = :parent_node_id
		          connect by node_id = prior parent_id) nodes
                    where nodes.object_id = apm_packages.package_id
                      and apm_packages.package_id = ag.package_id
                      and tree_rownum=1
		
      </querytext>
</fullquery>

 
<fullquery name="application_group::new.add_group">      
      <querytext>
      
		begin
		:1 := application_group.new (
	            group_id      => :group_id,
	            object_type    => :group_type,
	            group_name    => :group_name,
                    package_id    => :package_id,
	            context_id    => :parent_group_id,
	            creation_user => :creation_user,
	            creation_ip   => :creation_ip,
		    email         => :email,
		    url           => :url
		);
		end;
	    
      </querytext>
</fullquery>

</queryset>
