<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

   <fullquery name="lang::system::timezone_utc_offset.system_utc_offset">
      <querytext>
      
        select (extract(epoch from current_timestamp
                          + timezone__get_offset (timezone__get_id(:system_timezone), current_timestamp)
                         )
                - extract(epoch from current_timestamp)
               ) / 60/60;
    
      </querytext>
   </fullquery>
 
</queryset>
