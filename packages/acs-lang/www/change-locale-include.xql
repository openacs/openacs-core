<?xml version="1.0"?>
<queryset>

<fullquery name="all_timezones">
    <querytext>
        select tz || ' ' || gmt_offset as tz,
               tz
        from   timezones
    </querytext>
</fullquery>
	        
</queryset>
	                            
