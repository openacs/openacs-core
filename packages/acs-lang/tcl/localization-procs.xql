<?xml version="1.0"?>
<queryset>

   <fullquery name="lc_monetary_currency.lc_currency_select">      
      <querytext>
      
	select fractional_digits,
               html_entity 
        from   currency_codes 
        where  iso = :currency
    
      </querytext>
   </fullquery>

 
   <fullquery name="lc_list_all_timezones.all_timezones">      
      <querytext>
      select distinct tz, gmt_offset from timezones order by tz
      </querytext>
   </fullquery>

 
</queryset>
