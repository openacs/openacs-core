<?xml version="1.0"?>
<queryset>

<fullquery name="ad_pretty_mailing_address_from_args.user_name_select">      
      <querytext>
      
		select first_names, last_name, email
		from persons, parties
		where person_id = :user_id
		and person_id = party_id
	    
      </querytext>
</fullquery>

 
<fullquery name="ad_parameter_cache_all.parameters_get_all">      
      <querytext>
      
	select v.package_id, p.parameter_name, v.attr_value
	from apm_parameters p, apm_parameter_values v
	where p.parameter_id = v.parameter_id
    
      </querytext>
</fullquery>

 
</queryset>
