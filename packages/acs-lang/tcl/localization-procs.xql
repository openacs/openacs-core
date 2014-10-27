<?xml version="1.0"?>
<queryset>

   <fullquery name="lc_list_all_timezones.all_timezones">      
      <querytext>
      select distinct tz, gmt_offset from timezones order by tz
      </querytext>
   </fullquery>

 
</queryset>