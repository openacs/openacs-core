<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>
 
<fullquery name="sysdate">
    <querytext>
	select to_char(current_timestamp, 'YYYY-MM-DD HH24:MI:SS')
    </querytext>
</fullquery>

  <fullquery name="sysdate_utc">      
    <querytext>
      select to_char(timezone__convert_to_utc(timezone__get_id(:system_timezone), to_char(current_timestamp, 'YYYY-MM-DD HH24:MI:SS')), 'YYYY-MM-DD HH24:MI:SS')
    </querytext>
  </fullquery>
 

	        
</queryset>
	                            
