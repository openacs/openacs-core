<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

   <fullquery name="lang::system::timezone_utc_offset.system_utc_offset">      
      <querytext>
      
	select ( (sysdate - timezone.local_to_utc (timezone.get_id(:system_timezone), sysdate)) * 24 ) from dual
    
      </querytext>
   </fullquery>
 
</queryset>
