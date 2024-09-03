--
-- delete parameter 'EnableLoggingP', which was renamed to 'ClusterEnableLoggingP'
--
delete from apm_parameter_values where apm_parameter_values.parameter_id in (
   select p.parameter_id from apm_parameters p
   where package_key = 'acs-kernel' and parameter_name = 'EnableLoggingP'
);

delete from apm_parameters where apm_parameters.parameter_id in (
   select p.parameter_id from apm_parameters p
   where package_key = 'acs-kernel' and parameter_name = 'EnableLoggingP'
);

--
-- delete parameter 'PreferredLocationRegexp', which was renamed to 'ClusterPreferredLocationRegexp'
--
delete from apm_parameter_values where apm_parameter_values.parameter_id in (
   select p.parameter_id from apm_parameters p
   where package_key = 'acs-kernel' and parameter_name = 'PreferredLocationRegexp'
);
delete from apm_parameters where apm_parameters.parameter_id in (
   select p.parameter_id from apm_parameters p
   where package_key = 'acs-kernel' and parameter_name = 'PreferredLocationRegexp'
);
