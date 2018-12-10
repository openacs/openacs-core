<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

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
