<?xml version="1.0"?>
<queryset>

<fullquery name="all_states">      
      <querytext>
      
	select state_name, abbrev from states order by state_name
    
      </querytext>
</fullquery>

 
<fullquery name="all_countries">      
      <querytext>
      
	select default_name, iso from countries order by default_name 
    
      </querytext>
</fullquery>

 
<fullquery name="ad_db_select_widget.currency_info">      
      <querytext>
      
	select currency_name, iso 
	from currency_codes 
	where supported_p='t'
	order by currency_name 
    
      </querytext>
</fullquery>

 
</queryset>
