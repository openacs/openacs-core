<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>
 
<fullquery name="sysdate">
    <querytext>
	select to_char(current_time, 'YYYY-MM-DD HH24:MI:SS')
    </querytext>
</fullquery>
	        
</queryset>
	                            