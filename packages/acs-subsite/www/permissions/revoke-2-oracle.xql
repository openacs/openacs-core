<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="revoke">      
      <querytext>
      
		begin
		    acs_permission.revoke_permission(:object_id, :party_id, :privilege);
		end;
	    
      </querytext>
</fullquery>

 
</queryset>
