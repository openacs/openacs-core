<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="lc_time_utc_to_local.utc_to_local">      
      <querytext>

	    select to_char(timezone__convert_to_local(timezone__get_id(:tz), :time_value), 'YYYY-MM-DD HH24:MI:SS')
	
      </querytext>
</fullquery>

 
<fullquery name="lc_time_local_to_utc.local_to_utc">      
      <querytext>

	    select  to_char(timezone__convert_to_utc(timezone__get_id(:tz), :time_value), 'YYYY-MM-DD HH24:MI:SS')
	
      </querytext>
</fullquery>

 
<fullquery name="lc_time_tz_convert.convert">
      <querytext>
      

           select to_char(     
                          timezone__convert_to_local(timezone__get_id(:to), 
                                                to_char(timezone__convert_to_utc(timezone__get_id(:from), :time_value), 'YYYY-MM-DD HH24:MI:SS')
                                                ), 'YYYY-MM-DD HH24:MI:SS')
	
      </querytext>
</fullquery>

</queryset>
