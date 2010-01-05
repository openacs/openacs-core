<?xml version="1.0"?>

<queryset>

  <fullquery name="get_timezones">
    <querytext>
      select tz || ' ' || gmt_offset as full_tz, tz
      from timezones
      order by tz
    </querytext>
  </fullquery>
  
  <fullquery name="get_locales">
    <querytext>
      select label, locale
      from enabled_locales
      order by label
    </querytext>
  </fullquery>            

</queryset>
