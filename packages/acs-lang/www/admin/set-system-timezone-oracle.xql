<?xml version="1.0"?>

<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

  <fullquery name="sysdate">      
    <querytext>
      select to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS') from dual 
    </querytext>
  </fullquery>

  <fullquery name="sysdate_utc">      
    <querytext>
      select to_char(timezone.local_to_utc(timezone.get_id(:system_timezone), sysdate), 'YYYY-MM-DD HH24:MI:SS') from dual
    </querytext>
  </fullquery>
 
</queryset>
