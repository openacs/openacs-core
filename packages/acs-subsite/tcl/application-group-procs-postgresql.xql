<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="contains_party_p.app_group_contains_party_p">      
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
            
	
      </querytext>
</fullquery>

 
<fullquery name="contains_party_p.app_group_contains_party_p">      
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
            
	
      </querytext>
</fullquery>

 
<fullquery name="contains_relation_p.app_group_contains_rel_p">      
      <querytext>
      
	    select case when exists (
	        select 1
	        from application_group_element_map
	        where package_id = :package_id
	          and rel_id = :rel_id
	    ) then 1 else 0 end
            
	
      </querytext>
</fullquery>

 
<fullquery name="contains_segment_p.app_group_contains_segment_p">      
      <querytext>
      
	    select case when exists (
	        select 1
	        from application_group_segments
	        where package_id = :package_id
	          and segment_id = :segment_id
	    ) then 1 else 0 end
            
	
      </querytext>
</fullquery>

 
<fullquery name="group_id_from_package_id.application_group_from_package_id_query">      
      <querytext>
--      FIX ME PLSQL 
--	    begin
	    select application_group__group_id_from_package_id (
	        :package_id,            -- package_id
	        :no_complain_p          -- no_complain_p
	    );
--	    end;
	
      </querytext>
</fullquery>

 
<fullquery name="new.parent_group_id_query">      
      <querytext>
--      FIX ME ROWNUM
		    select ag__group_id as parent_group_id
		    from application_groups ag,
		         apm_packages,
		         (select object_id, rownum as tree_rownum
		          from site_nodes
		          start with node_id = :node_id
		          connect by node_id = prior parent_id) nodes
                    where nodes__object_id = apm_packages.package_id
                      and apm_packages.package_id = ag.package_id
                      limit 1

      </querytext>
</fullquery>


<fullquery name="new.add_group">
      <querytext>
--      FIX ME PLSQL
--	begin
                select application_group_new (
	            :group_id,          -- group_id
	            :group_type,        -- object_type
	            :group_name,        -- group_name
                    :package_id,        -- package_id
	            :context_id,        -- context_id
	            :creation_user,     -- creation_user
	            :creation_ip,       -- creation_ip
		    :email,             -- email
		    :url                -- url
		);
--	end;

      </querytext>
</fullquery>

 
<fullquery name="new.add_composition_rel">      
      <querytext>
--      FIX ME PLSQL
--    begin
        select composition_rel__new (
		            'composition_rel',          -- rel_type
		            :parent_group_id,           -- object_id_one
		            :group_id,                  -- object_id_two
		            :creation_user,             -- creation_user
                            :creation_ip                -- creation_ip
		    );
--    end;

      </querytext>
</fullquery>


</queryset>
