<?xml version="1.0"?>
<queryset>

<fullquery name="all_timezones">
    <querytext>
        select tz || ' ' || gmt_offset as tz,
               tz
        from   timezones
    </querytext>
</fullquery>

<fullquery name="locale_loop">
    <querytext>
        select label,   
               locale
          from enabled_locales
         order by label
    </querytext>
</fullquery>	        
</queryset>
	                            
