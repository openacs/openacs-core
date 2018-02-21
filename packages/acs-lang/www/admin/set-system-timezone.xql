<?xml version="1.0"?>
<queryset>
 
  <fullquery name="sysdate">
    <querytext>
      select to_char(current_timestamp, 'YYYY-MM-DD HH24:MI:SS') from dual
    </querytext>
  </fullquery>

  <fullquery name="sysdate_utc">      
    <querytext>
      select to_char(current_timestamp at time zone 'UTC', 'YYYY-MM-DD HH24:MI:SS') from dual
    </querytext>
  </fullquery>
	        
</queryset>
	                            
