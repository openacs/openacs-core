<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

   <fullquery name="lang::system::timezone_utc_offset.system_utc_offset">
      <querytext>
      
	select ( (current_time - timezone__local_to_utc (:system_timezone, current_time)) * 24 )
    
      </querytext>
   </fullquery>
 
</queryset>
