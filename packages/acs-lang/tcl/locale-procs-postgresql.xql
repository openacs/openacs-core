<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

   <fullquery name="lang::system::timezone_utc_offset.system_utc_offset">
      <querytext>
      
	select timezone__get_offset (timezone__get_id(:system_timezone), current_timestamp)
    
      </querytext>
   </fullquery>
 
</queryset>
