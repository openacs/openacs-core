<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="ad_locale_system_tz_offset.system_offset">      
      <querytext>
      
	select timezone__get_offset (timezone__get_id(:system_timezone), current_timestamp)
    
      </querytext>
</fullquery>

 
</queryset>
