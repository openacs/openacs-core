<?xml version="1.0"?>
<queryset>

<fullquery name="no_alerts_until">      
      <querytext>
      
    select no_alerts_until from users where user_id = :user_id

      </querytext>
</fullquery>

 
<fullquery name="pvt_unset_no_alerts_until">      
      <querytext>
      
	    update users 
	    set no_alerts_until = :clear
	    where user_id = :user_id
    
      </querytext>
</fullquery>

 
</queryset>
