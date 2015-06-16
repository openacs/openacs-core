-- Change default value to reflect new semantics found in code
update apm_parameters
   set default_value = '1',
       description = 'send confirmation email to user after registration.'
 where parameter_id =
       (select parameter_id
       	  from apm_parameters
         where package_key = 'acs-subsite'
	   and parameter_name = 'EmailRegistrationConfirmationToUserP')
;

-- Update all current values to reflect new semantics found in code
update apm_parameter_values
   set attr_value = (case attr_value
       		     when '-1' then '0'
		     when  '0' then '1'
		     else           '1'
		     end)
 where parameter_id =
       (select parameter_id
       	  from apm_parameters
         where package_key = 'acs-subsite'
	   and parameter_name = 'EmailRegistrationConfirmationToUserP')
;
