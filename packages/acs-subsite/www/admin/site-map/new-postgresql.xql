<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="node_new">      
      <querytext>

        select site_node__new (
         :new_node_id,
         :parent_id,
         :name,
	 null,
         :directory_p,
         :pattern_p,
         :user_id,
         :ip_address
        )
    
      </querytext>
</fullquery>

 
</queryset>
