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

  <fullquery name="ad_parameter_cache.select_global_parameter_value">      
    <querytext>
      select apm_parameter_values.attr_value
      from apm_parameters, apm_parameter_values
      where apm_parameter_values.package_id is null
      and apm_parameter_values.parameter_id = apm_parameters.parameter_id
      and apm_parameters.parameter_name = :parameter_name
    </querytext>
  </fullquery>

  <fullquery name="ad_parameter_cache.select_instance_parameter_value">      
    <querytext>
      select apm_parameter_values.attr_value
      from apm_parameters, apm_parameter_values
      where apm_parameter_values.package_id = :key
      and apm_parameter_values.parameter_id = apm_parameters.parameter_id
      and apm_parameters.parameter_name = :parameter_name
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
