<?xml version="1.0"?>
      
<queryset>
	<fullquery name="remove_notify"> 
		   <querytext>
			delete from notification_requests where request_id=:r_id 
		   </querytext>
	</fullquery>
</queryset>
