<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

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
