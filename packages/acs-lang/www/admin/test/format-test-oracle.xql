<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="lang_system_time_select">      
      <querytext>
      SELECT to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS') AS system_time FROM dual
      </querytext>
</fullquery>

 
</queryset>
