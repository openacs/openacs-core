<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="ad_locale_system_tz_offset.system_offset">      
      <querytext>
      
	select ( (current_timestamp - timezone__local_to_utc (:system_timezone, current_timestamp)) * 24 )
	
    
      </querytext>
</fullquery>

 
</queryset>
