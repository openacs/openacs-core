<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="application_group::contains_relation_p.app_group_contains_rel_p">      
      <querytext>
      
	    select case when exists (
	        select 1
	        from application_group_element_map
	        where package_id = :package_id
	          and rel_id = :rel_id
	    ) then 1 else 0 end
            
	
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
            
	
      </querytext>
</fullquery>

 
<fullquery name="application_group::group_id_from_package_id.application_group_from_package_id_query">      
      <querytext>

	    select application_group__group_id_from_package_id (
	        :package_id,
	        :no_complain_p
	    )
	
      </querytext>
</fullquery>
 
<fullquery name="application_group::new.add_group">      
      <querytext>

		select application_group__new (
	            :group_id,
	            :group_type,
		    now(),
	            :creation_user,
	            :creation_ip,
		    :email,
		    :url,
	            :group_name,
                    :package_id,
                    null,
	            :package_id
		)
	    
      </querytext>
</fullquery>
 
<fullquery name="application_group::delete.delete">      
      <querytext>

		select application_group__delete (
	            :group_id
		)
	    
      </querytext>
</fullquery>
 
</queryset>
