<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

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

 
<fullquery name="application_group::new.add_group">      
      <querytext>
      
		begin
		:1 := application_group.new (
	            group_id      => :group_id,
	            object_type    => :group_type,
	            group_name    => :group_name,
                    package_id    => :package_id,
	            context_id    => :package_id,
	            creation_user => :creation_user,
	            creation_ip   => :creation_ip,
		    email         => :email,
		    url           => :url,
                    join_policy   => null
		);
		end;
	    
      </querytext>
</fullquery>
 
<fullquery name="application_group::delete.delete">      
      <querytext>
      
		begin
		application_group.del (
	                group_id      => :group_id
		);
		end;
	    
      </querytext>
</fullquery>

</queryset>
