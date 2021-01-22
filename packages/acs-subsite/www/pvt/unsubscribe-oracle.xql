<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="vacation_time">      
      <querytext>
      select no_alerts_until, acs_user.receives_alerts_p(:user_id) as on_vacation_p 
from users
where user_id = :user_id
      </querytext>
</fullquery>

 
</queryset>
